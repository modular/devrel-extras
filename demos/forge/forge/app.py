from __future__ import annotations

from fastapi import FastAPI, Form, HTTPException, Request
from fastapi.responses import FileResponse, HTMLResponse, JSONResponse, RedirectResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from forge.compare import get_current_compare, has_in_flight_lanes, start_compare
from forge.events import sse_stream
from forge.models import load_setup_profile_rows, profiles_by_keys
from forge.paths import sandbox_dir, static_dir, templates_dir
from forge.prompts import example_by_id, load_example_prompts, resolve_prompt_from_form

from forge.env import MAX_AGENT_TURNS_PER_LANE, load_env, modular_api_key

load_env()

app = FastAPI(title="Forge", version="0.1.0")
templates = Jinja2Templates(directory=str(templates_dir()))
app.mount("/static", StaticFiles(directory=str(static_dir())), name="static")


@app.get("/")
async def index(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        request,
        "index.html",
        {
            "profiles": load_setup_profile_rows(),
            "examples": load_example_prompts(),
        },
    )


@app.get("/api/compare/in-flight")
async def compare_in_flight() -> JSONResponse:
    return JSONResponse({"in_flight": has_in_flight_lanes()})


@app.post("/compare")
async def post_compare(
    request: Request,
    profile_keys: list[str] = Form(default=[]),
    prompt_id: str = Form(""),
    prompt_text: str = Form(""),
) -> RedirectResponse:
    keys = [k.strip() for k in profile_keys if k.strip()]
    unique = list(dict.fromkeys(keys))
    if len(unique) < 1 or len(unique) > 4:
        raise HTTPException(status_code=400, detail="Select 1 to 4 models")

    try:
        profiles = profiles_by_keys(unique)
        resolved = resolve_prompt_from_form(
            prompt_id=prompt_id or None,
            prompt_text=prompt_text or None,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    if modular_api_key() is None:
        raise HTTPException(
            status_code=400,
            detail="Set MODULAR_API_KEY in demos/forge/.env (see .env.example)",
        )

    label = (prompt_id or "").strip()
    custom_brief = (prompt_text or "").strip()
    if label:
        ex = example_by_id(label)
        prompt_label = ex.title if ex else label
    elif custom_brief:
        first_line = custom_brief.splitlines()[0].strip()
        if len(first_line) > 72:
            prompt_label = first_line[:71] + "…"
        else:
            prompt_label = first_line or "Custom prompt"
    else:
        prompt_label = "Custom prompt"

    start_compare(
        resolved=resolved,
        prompt_label=prompt_label,
        profiles=profiles,
        max_turns=MAX_AGENT_TURNS_PER_LANE,
    )
    return RedirectResponse(url="/compare", status_code=303)


@app.get("/compare")
async def compare_page(request: Request) -> HTMLResponse:
    session = get_current_compare()
    if session is None:
        raise HTTPException(
            status_code=404,
            detail="No compare in progress — start one from the setup page",
        )

    lanes = [
        {
            "run_id": lane.run_id,
            "label": lane.profile.label,
            "model": lane.profile.model,
            "events_url": f"/api/runs/{lane.run_id}/events",
            "preview_url": f"/sandbox/{lane.run_id}/index.html",
        }
        for lane in session.lanes
    ]
    return templates.TemplateResponse(
        request,
        "compare.html",
        {
            "prompt_label": session.prompt_label,
            "resolved": session.resolved,
            "lanes": lanes,
        },
    )


@app.get("/api/runs/{run_id}/events")
async def run_events(run_id: str) -> StreamingResponse:
    def generate():
        for chunk in sse_stream(run_id):
            yield chunk

    return StreamingResponse(
        generate(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


@app.get("/sandbox/{run_id}/{file_path:path}")
async def sandbox_file(run_id: str, file_path: str) -> FileResponse:
    root = sandbox_dir(run_id)
    if not root.is_dir():
        raise HTTPException(status_code=404, detail="Sandbox not found")
    target = (root / file_path).resolve()
    if not str(target).startswith(str(root.resolve())):
        raise HTTPException(status_code=403, detail="Invalid path")
    if not target.is_file():
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(target)


@app.get("/sandbox/{run_id}/")
async def sandbox_index(run_id: str) -> FileResponse:
    return await sandbox_file(run_id, "index.html")
