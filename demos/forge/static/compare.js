(function () {
  document.querySelectorAll(".lane").forEach(function (lane) {
    var url = lane.dataset.eventsUrl;
    var dialog = lane.querySelector(".trace-dialog");
    var trace = lane.querySelector(".lane-trace");
    var traceOpen = lane.querySelector(".lane-trace-open");
    var traceClose = lane.querySelector(".trace-dialog-close");
    var statusText = lane.querySelector(".lane-status-text");
    var elapsedEl = lane.querySelector(".lane-elapsed-value");
    var usageStat = lane.querySelector(".lane-stat--usage");
    var inEl = lane.querySelector(".lane-stat-in");
    var outEl = lane.querySelector(".lane-stat-out");
    var cacheStat = lane.querySelector(".lane-stat--cache");
    var cacheEl = lane.querySelector(".lane-stat-cache");
    var costStat = lane.querySelector(".lane-stat--cost");
    var costEl = lane.querySelector(".lane-stat-cost");
    var previewOpen = lane.querySelector(".lane-preview-open");
    var buildingFrame = lane.querySelector(".lane-building");
    var iframe = lane.querySelector(".lane-preview");
    var previewBase = lane.dataset.previewUrl || "";
    var streamDone = false;
    var startedAtMs = null;
    var endedAtMs = null;
    var frozenElapsedMs = null;
    var tickId = null;

    function setStatus(label) {
      if (statusText) statusText.textContent = label;
    }

    function formatElapsed(ms) {
      var totalSec = Math.max(0, Math.floor(ms / 1000));
      var minutes = Math.floor(totalSec / 60);
      var seconds = totalSec % 60;
      if (minutes > 0) {
        return minutes + "m " + seconds + "s";
      }
      return seconds + "s";
    }

    function elapsedLabel() {
      if (frozenElapsedMs != null) {
        return formatElapsed(frozenElapsedMs);
      }
      if (startedAtMs == null) {
        return "—";
      }
      var end = endedAtMs != null ? endedAtMs : Date.now();
      return formatElapsed(end - startedAtMs);
    }

    function renderElapsed() {
      if (elapsedEl) elapsedEl.textContent = elapsedLabel();
      if (startedAtMs != null || frozenElapsedMs != null) {
        lane.classList.add("lane--has-elapsed");
      }
    }

    function startTick() {
      if (tickId != null) return;
      tickId = window.setInterval(renderElapsed, 250);
    }

    function stopTick() {
      if (tickId == null) return;
      window.clearInterval(tickId);
      tickId = null;
    }

    function applyStarted(payload) {
      frozenElapsedMs = null;
      endedAtMs = null;
      var fromServer = payload.started_at_ms;
      if (fromServer != null && Number.isFinite(Number(fromServer))) {
        startedAtMs = Number(fromServer);
      } else if (startedAtMs == null) {
        startedAtMs = Date.now();
      }
      renderElapsed();
      startTick();
    }

    function applyFinished(payload) {
      if (payload.started_at_ms != null && startedAtMs == null) {
        startedAtMs = Number(payload.started_at_ms);
      }
      if (payload.ended_at_ms != null) {
        endedAtMs = Number(payload.ended_at_ms);
      }
      if (payload.elapsed_ms != null) {
        frozenElapsedMs = Number(payload.elapsed_ms);
      } else if (startedAtMs != null && endedAtMs != null) {
        frozenElapsedMs = Math.max(0, endedAtMs - startedAtMs);
      }
      stopTick();
      renderElapsed();
      applyMetrics(payload);
    }

    function formatCount(n) {
      var v = Math.max(0, Number(n) || 0);
      if (v >= 1000000) return (v / 1000000).toFixed(1).replace(/\.0$/, "") + "M";
      if (v >= 10000) return Math.round(v / 1000) + "k";
      if (v >= 1000) return (v / 1000).toFixed(1).replace(/\.0$/, "") + "k";
      return String(v);
    }

    function formatUsd(n) {
      var v = Number(n);
      if (!Number.isFinite(v)) return null;
      if (v >= 1) return "$" + v.toFixed(2);
      if (v >= 0.01) return "$" + v.toFixed(3);
      return "$" + v.toFixed(4);
    }

    function applyMetrics(payload) {
      if (!payload.tokens_available) return;
      var inputTok = Number(payload.input_tokens) || 0;
      var outputTok = Number(payload.output_tokens) || 0;
      if (inEl) inEl.textContent = formatCount(inputTok);
      if (outEl) outEl.textContent = formatCount(outputTok);
      if (usageStat) usageStat.hidden = false;

      var cached = Number(payload.cached_input_tokens) || 0;
      if (cacheStat && cacheEl) {
        if (cached > 0) {
          cacheEl.textContent = formatCount(cached);
          cacheStat.hidden = false;
        } else {
          cacheStat.hidden = true;
        }
      }

      if (costStat && costEl) {
        if (payload.cost_available && payload.cost_usd != null) {
          var usd = formatUsd(payload.cost_usd);
          if (usd) {
            costEl.textContent = usd;
            costStat.hidden = false;
          }
        }
      }
    }

    function appendTrace(text) {
      if (!text || !trace) return;
      var chunk = String(text).trim();
      if (!chunk) return;
      if (trace.textContent.length > 0) {
        trace.textContent += "\n\n";
      }
      trace.textContent += chunk;
      if (traceOpen) traceOpen.classList.add("has-trace");
      if (dialog && dialog.open) {
        trace.scrollTop = trace.scrollHeight;
      }
    }

    function openTrace() {
      if (!dialog) return;
      if (typeof dialog.showModal === "function") {
        dialog.showModal();
      }
      if (trace) trace.scrollTop = trace.scrollHeight;
    }

    if (traceOpen) {
      traceOpen.addEventListener("click", openTrace);
    }
    if (traceClose && dialog) {
      traceClose.addEventListener("click", function () {
        dialog.close();
      });
    }

    function hidePreviewOpen() {
      if (!previewOpen) return;
      previewOpen.hidden = true;
      previewOpen.setAttribute("aria-hidden", "true");
      previewOpen.tabIndex = -1;
      previewOpen.setAttribute("href", "#");
    }

    function showPreviewOpen() {
      if (!previewOpen || !previewBase) return;
      previewOpen.href = previewBase + "?t=" + Date.now();
      previewOpen.hidden = false;
      previewOpen.removeAttribute("aria-hidden");
      previewOpen.tabIndex = 0;
    }

    hidePreviewOpen();

    function revealSandboxPreview() {
      if (!iframe || !previewBase) return;
      iframe.src = previewBase + "?t=" + Date.now();
      iframe.hidden = false;
      lane.classList.add("lane--preview-live");
      if (buildingFrame) buildingFrame.hidden = true;
      showPreviewOpen();
    }

    var source = new EventSource(url);
    source.onmessage = function (ev) {
      var event;
      try {
        event = JSON.parse(ev.data);
      } catch (_) {
        return;
      }
      var type = event.type;
      var payload = event.payload || {};

      if (type === "trace" || type === "log") {
        appendTrace(payload.text || "");
      }
      if (type === "run_started") {
        setStatus("Building");
        hidePreviewOpen();
        applyStarted(payload);
      }
      if (type === "metrics") {
        applyMetrics(payload);
      }
      if (type === "error") {
        appendTrace("ERROR: " + (payload.message || "unknown"));
        setStatus("Failed");
        hidePreviewOpen();
        lane.classList.add("lane--failed");
      }
      if (type === "done") {
        streamDone = true;
        applyFinished(payload);
        var ok = payload.has_preview === true;
        setStatus(ok ? "Complete" : "Failed");
        lane.classList.add(ok ? "lane--done" : "lane--failed");
        if (ok) {
          revealSandboxPreview();
        } else {
          hidePreviewOpen();
        }
        source.close();
      }
    };
    source.onerror = function () {
      if (streamDone) return;
      if (source.readyState === EventSource.CONNECTING) return;
      setStatus("Disconnected");
      hidePreviewOpen();
      lane.classList.add("lane--failed");
      stopTick();
    };
  });

  (function () {
    var openBtn = document.querySelector(".compare-prompt-open");
    var dialog = document.getElementById("compare-prompt-dialog");
    if (!openBtn || !dialog) return;
    var closeBtn = dialog.querySelector(".compare-prompt-close");
    openBtn.addEventListener("click", function () {
      if (typeof dialog.showModal === "function") {
        dialog.showModal();
      }
    });
    if (closeBtn) {
      closeBtn.addEventListener("click", function () {
        dialog.close();
      });
    }
  })();
})();
