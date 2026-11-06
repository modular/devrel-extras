(function () {
  var customSwitch = document.getElementById("prompt_custom_switch");
  var presetPanel = document.getElementById("prompt_preset_panel");
  var customPanel = document.getElementById("prompt_custom_panel");
  var promptText = document.getElementById("prompt_text");
  var promptRadios = document.querySelectorAll('input[name="prompt_id"]');
  var form = document.querySelector(".setup-form");
  var customMode = false;
  var modelSelect = document.getElementById("model_select");
  var modelSelectOpen = false;
  var SUMMARY_PLUS_SVG =
    '<svg class="ui-icon ui-icon--plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14"/><path d="M12 5v14"/></svg>';

  function renderModelSelectSummary(container, labels) {
    if (!container) return;
    container.textContent = "";
    labels.forEach(function (label, index) {
      if (index > 0) {
        var sep = document.createElement("span");
        sep.className = "model-select-summary-sep";
        sep.setAttribute("aria-hidden", "true");
        sep.innerHTML = SUMMARY_PLUS_SVG;
        container.appendChild(sep);
      }
      var item = document.createElement("span");
      item.className = "model-select-summary-item";
      item.textContent = label;
      container.appendChild(item);
    });
  }

  function setModelSelectOpen(open) {
    if (!modelSelect) return;
    var trigger = document.getElementById("model_select_trigger");
    var panel = document.getElementById("model_select_panel");
    modelSelectOpen = !!open;
    modelSelect.classList.toggle("model-select--open", modelSelectOpen);
    if (panel) panel.hidden = !modelSelectOpen;
    if (trigger) trigger.setAttribute("aria-expanded", modelSelectOpen ? "true" : "false");
  }

  function selectedModelCheckboxes() {
    if (!modelSelect) return [];
    return Array.prototype.filter.call(
      modelSelect.querySelectorAll('input[name="profile_keys"]'),
      function (cb) {
        return cb.checked;
      }
    );
  }

  function updateModelSelectLabel() {
    if (!modelSelect) return true;
    var summaryEl = document.getElementById("model_select_summary");
    var trigger = document.getElementById("model_select_trigger");
    var minModels = parseInt(modelSelect.getAttribute("data-min") || "1", 10);
    var maxModels = parseInt(modelSelect.getAttribute("data-max") || "4", 10);
    var selected = selectedModelCheckboxes();
    var labels = selected.map(function (cb) {
      var tile = cb.closest(".model-tile");
      var title = tile && tile.querySelector(".model-tile-title");
      return title ? title.textContent.trim() : cb.value;
    });
    var placeholder = document.getElementById("model_select_placeholder");
    if (summaryEl) {
      renderModelSelectSummary(summaryEl, labels);
    }
    if (trigger) {
      trigger.classList.toggle("model-select-trigger--empty", labels.length === 0);
      trigger.setAttribute(
        "aria-label",
        labels.length === 0
          ? "Models. Choose 1 to 4."
          : "Models: " + labels.join(", ")
      );
    }
    if (placeholder) {
      placeholder.hidden = labels.length > 0;
    }
    var statusEl = document.getElementById("model_select_status");
    if (statusEl) {
      statusEl.textContent = labels.length + " of " + maxModels + " selected";
      statusEl.classList.toggle(
        "model-select-status--ok",
        labels.length >= minModels && labels.length <= maxModels
      );
    }
    selected.forEach(function (cb) {
      var option = cb.closest('[role="option"]');
      if (option) option.setAttribute("aria-selected", "true");
    });
    Array.prototype.forEach.call(
      modelSelect.querySelectorAll('[role="option"]'),
      function (option) {
        var input = option.querySelector('input[name="profile_keys"]');
        if (input && !input.checked) option.setAttribute("aria-selected", "false");
      }
    );
    var count = selected.length;
    var valid = count >= minModels && count <= maxModels;
    if (trigger) {
      trigger.setAttribute("aria-invalid", valid ? "false" : "true");
      trigger.classList.toggle("model-select-trigger--warn", count > 0 && !valid);
    }
    return valid;
  }

  function bindModelSelect() {
    if (!modelSelect) return;
    var trigger = document.getElementById("model_select_trigger");
    var minModels = parseInt(modelSelect.getAttribute("data-min") || "1", 10);
    var maxModels = parseInt(modelSelect.getAttribute("data-max") || "4", 10);
    var checkboxes = modelSelect.querySelectorAll('input[name="profile_keys"]');

    if (trigger) {
      trigger.addEventListener("click", function () {
        setModelSelectOpen(!modelSelectOpen);
      });
    }

    document.addEventListener("click", function (e) {
      if (!modelSelect.contains(e.target)) setModelSelectOpen(false);
    });

    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") setModelSelectOpen(false);
    });

    checkboxes.forEach(function (cb) {
      cb.addEventListener("change", function () {
        var selected = selectedModelCheckboxes();
        if (selected.length > maxModels) {
          cb.checked = false;
          updateModelSelectLabel();
          return;
        }
        if (!cb.checked && selected.length < minModels) {
          cb.checked = true;
          updateModelSelectLabel();
          return;
        }
        updateModelSelectLabel();
      });
    });

    updateModelSelectLabel();
  }

  function setCustomMode(on) {
    customMode = !!on;
    if (presetPanel) presetPanel.hidden = customMode;
    if (customPanel) customPanel.hidden = !customMode;
    if (customSwitch) {
      customSwitch.checked = customMode;
      customSwitch.setAttribute("aria-checked", customMode ? "true" : "false");
    }
    promptRadios.forEach(function (radio) {
      radio.disabled = customMode;
    });
    if (promptText) {
      promptText.disabled = !customMode;
      promptText.required = customMode;
      if (customMode) {
        window.requestAnimationFrame(function () {
          promptText.focus();
        });
      }
    }
  }

  if (customSwitch) {
    customSwitch.addEventListener("change", function () {
      setCustomMode(customSwitch.checked);
    });
  }

  if (form) {
    form.addEventListener("submit", function (e) {
      e.preventDefault();

      if (customMode) {
        if (promptText && !promptText.value.trim()) {
          setCustomMode(true);
          return;
        }
      }

      if (!updateModelSelectLabel()) {
        setModelSelectOpen(true);
        return;
      }

      function finishSubmit() {
        if (!customMode && promptText) promptText.disabled = true;
        HTMLFormElement.prototype.submit.call(form);
      }

      var confirmMsg =
        "Starting a new compare stops every Goose lane still running on this server (including compares open in other tabs). Continue?";

      fetch("/api/compare/in-flight")
        .then(function (res) {
          return res.json();
        })
        .then(function (data) {
          if (data && data.in_flight && !window.confirm(confirmMsg)) {
            return;
          }
          finishSubmit();
        })
        .catch(function () {
          finishSubmit();
        });
    });
  }

  setCustomMode(false);
  bindModelSelect();
})();
