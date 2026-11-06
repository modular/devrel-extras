# Vendored Three.js (offline sandboxes)

Agent-built 3D apps must not use a CDN. They import these files by relative path:

- `./vendor/three.module.min.js`
- `./vendor/OrbitControls.js`

Each Goose lane copies this folder into `data/sandbox/<run_id>/vendor/` before the agent runs (`forge/vendor.py`).

| File | Source | Notes |
|------|--------|-------|
| `three.module.min.js` | three@0.160.0 `build/three.module.min.js` | MIT |
| `OrbitControls.js` | three@0.160.0 `examples/jsm/controls/OrbitControls.js` | MIT; `from 'three'` rewritten to `from './three.module.min.js'` |

## Updating

Pin the same version as `config/threejs_3d.txt` (r160). After replacing files, run a 3D preset compare and confirm preview loads.

```bash
curl -o three.module.min.js "https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.module.min.js"
curl -o OrbitControls.js "https://cdn.jsdelivr.net/npm/three@0.160.0/examples/jsm/controls/OrbitControls.js"
sed -i '' "s|} from 'three';|} from './three.module.min.js';|" OrbitControls.js
```
