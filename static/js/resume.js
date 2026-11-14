(() => {
  "use strict";

  // Browsers without CSS anchor positioning get the popover placed by hand.
  const initDownloadPopover = () => {
    const trigger = document.getElementById("resume-download-btn");
    const popover = document.getElementById("resume-download-popover");
    if (!trigger || !popover) return;

    const positionFallback = () => {
      if (CSS.supports("position-area", "block-end")) return;
      const t = trigger.getBoundingClientRect();
      const p = popover.getBoundingClientRect();
      let top = t.bottom + 8;
      if (top + p.height > window.innerHeight - 12) top = Math.max(12, t.top - p.height - 8);
      const left = Math.max(12, Math.min(t.right - p.width, window.innerWidth - p.width - 12));
      popover.style.top = `${Math.round(top)}px`;
      popover.style.left = `${Math.round(left)}px`;
    };

    popover.addEventListener("toggle", (event) => {
      if (event.newState === "open") positionFallback();
    });
    window.addEventListener("resize", () => {
      if (popover.matches(":popover-open")) positionFallback();
    });
    popover.querySelectorAll("[data-popover-close]").forEach((link) =>
      link.addEventListener("click", () => popover.hidePopover?.())
    );
  };

  const initDensityToggle = () => {
    const root = document.getElementById("resume-root");
    const btns = Array.from(document.querySelectorAll("[data-density-choice]"));
    if (!root) return;
    btns.forEach((b) =>
      b.addEventListener("click", () => {
        const next = b.getAttribute("data-density-choice") === "short" ? "short" : "full";
        root.setAttribute("data-resume-density", next);
        btns.forEach((x) => x.setAttribute("aria-pressed", String(x === b)));
      })
    );
  };

  // Clicking a skill shows only the roles whose stack or summary mention it.
  const initSkillFilter = () => {
    const skillBtns = Array.from(document.querySelectorAll("[data-skill-filter]"));
    const roleCards = Array.from(document.querySelectorAll("[data-role-card]"));
    const bar = document.getElementById("resume-skill-filter-bar");
    const status = document.getElementById("resume-skill-filter-status");
    if (skillBtns.length === 0 || roleCards.length === 0) return;

    let activeSkill = null;

    // "Kubernetes (Talos/NKP)" also matches plain "kubernetes".
    const tokensFor = (label) => {
      const base = label.toLowerCase().trim();
      return [...new Set([base, base.replace(/\([^)]*\)/g, "").trim()])].filter((t) => t.length >= 2);
    };

    const toggle = (skill) => {
      activeSkill = activeSkill === skill ? null : skill;
      const tokens = activeSkill ? tokensFor(activeSkill) : [];
      let matched = 0;
      roleCards.forEach((card) => {
        const hay = card.getAttribute("data-role-tech") || "";
        const show = !activeSkill || tokens.some((tok) => hay.includes(tok));
        card.hidden = !show;
        if (show) matched += 1;
      });
      skillBtns.forEach((btn) =>
        btn.setAttribute("aria-pressed", String(activeSkill !== null && btn.getAttribute("data-skill-filter") === activeSkill))
      );
      if (bar && status) {
        bar.hidden = activeSkill === null;
        if (activeSkill) status.textContent = `Showing ${matched} of ${roleCards.length} roles that used ${activeSkill}`;
      }
    };

    skillBtns.forEach((btn) => btn.addEventListener("click", () => toggle(btn.getAttribute("data-skill-filter"))));
    document.getElementById("resume-skill-filter-clear")?.addEventListener("click", () => {
      if (activeSkill !== null) toggle(activeSkill);
    });
  };

  // The agent dialog shows /resume.md, generated from data/resume.yaml.
  const initAgentDialog = () => {
    const trigger = document.getElementById("agent-spec-trigger");
    const dialog = document.getElementById("agent-spec-dialog");
    const payload = document.getElementById("agent-spec-payload");
    if (!trigger || !dialog || !payload) return;
    let loaded = false;

    trigger.addEventListener("click", async () => {
      dialog.showModal();
      if (loaded) return;
      try {
        const res = await fetch(payload.dataset.src);
        if (!res.ok) throw new Error(String(res.status));
        payload.textContent = await res.text();
        loaded = true;
      } catch {
        payload.textContent = "resume.md isn't available. Run `generate` in the devenv shell to build it.";
      }
    });
    document.getElementById("agent-spec-close")?.addEventListener("click", () => dialog.close());
    dialog.addEventListener("click", (event) => {
      if (event.target === dialog) dialog.close();
    });
  };

  document.addEventListener("DOMContentLoaded", () => {
    initDownloadPopover();
    initDensityToggle();
    initSkillFilter();
    initAgentDialog();
  });
})();
