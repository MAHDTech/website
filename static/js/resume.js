(() => {
  "use strict";

  const initPopoverPositioning = () => {
    const trigger = document.getElementById("resume-download-btn");
    const popover = document.getElementById("resume-download-popover");
    if (!trigger || !popover) return;

    // Conditionally load popover polyfill only if native Popover API is absent
    if (!Object.hasOwn(HTMLElement.prototype, "popover")) {
      import("https://unpkg.com/@oddbird/popover-polyfill@latest/dist/popover.min.js").catch(
        () => {}
      );
    }

    const positionFallback = () => {
      if (typeof CSS !== "undefined" && CSS.supports("position-area", "block-end")) {
        return;
      }
      const trigRect = trigger.getBoundingClientRect();
      const popRect = popover.getBoundingClientRect();
      const gap = 8;
      let top = trigRect.bottom + gap;
      if (top + popRect.height > window.innerHeight - 12) {
        top = Math.max(12, trigRect.top - popRect.height - gap);
      }
      let left = trigRect.right - popRect.width;
      left = Math.max(12, Math.min(left, window.innerWidth - popRect.width - 12));

      popover.style.top = `${Math.round(top)}px`;
      popover.style.left = `${Math.round(left)}px`;
    };

    popover.addEventListener("toggle", (event) => {
      if (event.newState === "open") {
        positionFallback();
      }
    });

    window.addEventListener("resize", () => {
      if (popover.matches(":popover-open, .\\:popover-open")) {
        positionFallback();
      }
    });

    popover.querySelectorAll("[data-popover-close]").forEach((link) => {
      link.addEventListener("click", () => {
        if (typeof popover.hidePopover === "function") {
          try {
            popover.hidePopover();
          } catch {}
        }
      });
    });
  };

  const initDensityToggle = () => {
    const root = document.getElementById("resume-root");
    const btns = Array.from(document.querySelectorAll("[data-density-choice]"));
    if (!root || btns.length === 0) return;

    const setDensity = (mode) => {
      const next = mode === "short" ? "short" : "full";
      root.setAttribute("data-resume-density", next);
      btns.forEach((b) => {
        const active = b.getAttribute("data-density-choice") === next;
        b.setAttribute("aria-pressed", String(active));
        b.classList.toggle("bg-surface-raised", active);
        b.classList.toggle("text-accent-cyan", active);
        b.classList.toggle("font-semibold", active);
        b.classList.toggle("text-text-muted", !active);
      });
    };

    btns.forEach((b) => {
      b.addEventListener("click", () => {
        setDensity(b.getAttribute("data-density-choice") || "full");
      });
    });
  };

  const initSkillFilter = () => {
    const skillBtns = Array.from(document.querySelectorAll("[data-skill-filter]"));
    const roleCards = Array.from(document.querySelectorAll("[data-role-card]"));
    const bar = document.getElementById("resume-skill-filter-bar");
    const status = document.getElementById("resume-skill-filter-status");
    const clearBtn = document.getElementById("resume-skill-filter-clear");

    if (skillBtns.length === 0 || roleCards.length === 0) return;

    let activeSkill = null;

    const extractTokens = (raw) => {
      const base = raw.toLowerCase().trim();
      const parentheticalStripped = base.replace(/\([^)]*\)/g, "").trim();
      return Array.from(new Set([base, parentheticalStripped].filter((t) => t.length >= 2)));
    };

    const applyFilter = (skillLabel) => {
      activeSkill = activeSkill === skillLabel ? null : skillLabel;
      const tokens = activeSkill ? extractTokens(activeSkill) : [];
      let matched = 0;

      roleCards.forEach((card) => {
        const hay = card.getAttribute("data-role-tech") || "";
        const isMatch =
          !activeSkill || tokens.some((tok) => hay.includes(tok));
        card.hidden = !isMatch;
        if (isMatch) matched += 1;
      });

      skillBtns.forEach((btn) => {
        const pressed =
          activeSkill !== null && btn.getAttribute("data-skill-filter") === activeSkill;
        btn.setAttribute("aria-pressed", String(pressed));
        btn.classList.toggle("border-accent-cyan", pressed);
        btn.classList.toggle("bg-surface-active", pressed);
        btn.classList.toggle("text-accent-cyan", pressed);
        btn.classList.toggle("font-bold", pressed);
      });

      if (bar && status) {
        bar.hidden = activeSkill === null;
        if (activeSkill) {
          status.textContent = `Showing ${matched} of ${roleCards.length} engagements matching "${activeSkill}"`;
        }
      }
    };

    skillBtns.forEach((btn) => {
      btn.addEventListener("click", () => {
        const val = btn.getAttribute("data-skill-filter");
        if (val) applyFilter(val);
      });
    });

    if (clearBtn) {
      clearBtn.addEventListener("click", () => {
        if (activeSkill !== null) {
          applyFilter(activeSkill);
        }
      });
    }
  };

  const initAgentDialog = () => {
    const trigger = document.getElementById("agent-spec-trigger");
    const dialog = document.getElementById("agent-spec-dialog");
    const closeBtn = document.getElementById("agent-spec-close");
    if (!trigger || !dialog) return;

    trigger.addEventListener("click", () => {
      if (typeof dialog.showModal === "function") {
        dialog.showModal();
      }
    });

    if (closeBtn) {
      closeBtn.addEventListener("click", () => {
        dialog.close();
      });
    }

    dialog.addEventListener("click", (event) => {
      if (event.target === dialog) {
        dialog.close();
      }
    });
  };

  document.addEventListener("DOMContentLoaded", () => {
    initPopoverPositioning();
    initDensityToggle();
    initSkillFilter();
    initAgentDialog();
  });
})();
