(() => {
  "use strict";

  const STORAGE_KEY = "color-scheme";

  const getMetaEl = () => document.querySelector('meta[name="color-scheme"]');

  const getSystemScheme = () =>
    typeof window !== "undefined" &&
    typeof window.matchMedia === "function" &&
    window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";

  const getStoredScheme = () => {
    try {
      const val = localStorage.getItem(STORAGE_KEY);
      return val === "light" || val === "dark" ? val : null;
    } catch {
      return null;
    }
  };

  const getRenderedScheme = () => getStoredScheme() ?? getSystemScheme();

  const applyThemeState = (mode) => {
    const meta = getMetaEl();
    const validOverride = mode === "light" || mode === "dark" ? mode : null;

    if (meta) {
      meta.content = validOverride ?? "light dark";
    }

    const sys = getSystemScheme();

    document.querySelectorAll("[data-theme-toggle]").forEach((btn) => {
      const labelEl = btn.querySelector("[data-theme-label]");
      const sunIcon = btn.querySelector('[data-theme-icon="sun"]');
      const moonIcon = btn.querySelector('[data-theme-icon="moon"]');
      const autoIcon = btn.querySelector('[data-theme-icon="auto"]');

      if (sunIcon) sunIcon.classList.toggle("hidden", validOverride !== "light");
      if (moonIcon) moonIcon.classList.toggle("hidden", validOverride !== "dark");
      if (autoIcon) autoIcon.classList.toggle("hidden", validOverride !== null);

      if (labelEl) {
        labelEl.textContent = validOverride
          ? validOverride === "dark"
            ? "Dark"
            : "Light"
          : `Auto · ${sys === "dark" ? "Dark" : "Light"}`;
      }
    });

    document.querySelectorAll("[data-theme-choice]").forEach((btn) => {
      const choice = btn.getAttribute("data-theme-choice");
      const active =
        (choice === "system" && validOverride === null) || choice === validOverride;
      btn.setAttribute("aria-pressed", String(active));
      btn.classList.toggle("bg-surface-raised", active);
      btn.classList.toggle("text-accent-cyan", active);
      btn.classList.toggle("font-semibold", active);
      btn.classList.toggle("text-text-muted", !active);
    });
  };

  const setExplicitChoice = (choice) => {
    if (choice === "light" || choice === "dark") {
      try {
        localStorage.setItem(STORAGE_KEY, choice);
      } catch {}
      applyThemeState(choice);
    } else {
      try {
        localStorage.removeItem(STORAGE_KEY);
      } catch {}
      applyThemeState(null);
    }
  };

  // Two-state header toggle following modern-web-guidance dark-mode-toggle:
  // Target = opposite of currently rendered scheme. If target matches current
  // system preference, remove stored override so system auto-detect resumes.
  const toggleThemeOpposite = () => {
    const rendered = getRenderedScheme();
    const target = rendered === "dark" ? "light" : "dark";
    const system = getSystemScheme();

    if (target === system) {
      setExplicitChoice("system");
    } else {
      setExplicitChoice(target);
    }
  };

  const initThemeControls = () => {
    applyThemeState(getStoredScheme());

    document.querySelectorAll("[data-theme-toggle]").forEach((btn) => {
      if (btn.dataset.themeBound === "true") return;
      btn.dataset.themeBound = "true";
      btn.addEventListener("click", toggleThemeOpposite);
    });

    document.querySelectorAll("[data-theme-choice]").forEach((btn) => {
      if (btn.dataset.choiceBound === "true") return;
      btn.dataset.choiceBound = "true";
      btn.addEventListener("click", () => {
        setExplicitChoice(btn.getAttribute("data-theme-choice") || "system");
      });
    });

    // Keep Auto label accurate if OS color scheme changes (never clear stored override!)
    if (typeof window !== "undefined" && typeof window.matchMedia === "function") {
      const mql = window.matchMedia("(prefers-color-scheme: dark)");
      mql.addEventListener("change", () => {
        applyThemeState(getStoredScheme());
      });
    }

    // Cross-tab synchronization
    window.addEventListener("storage", (event) => {
      if (event.key === STORAGE_KEY) {
        applyThemeState(getStoredScheme());
      }
    });
  };

  const copyToClipboard = async (text) => {
    const payload = String(text ?? "");
    if (navigator.clipboard && typeof navigator.clipboard.writeText === "function") {
      try {
        await navigator.clipboard.writeText(payload);
        return true;
      } catch {}
    }

    const scratch = document.createElement("textarea");
    scratch.value = payload;
    scratch.setAttribute("readonly", "");
    scratch.style.position = "fixed";
    scratch.style.opacity = "0";
    document.body.appendChild(scratch);
    scratch.select();
    let ok = false;
    try {
      ok = document.execCommand("copy");
    } catch {
      ok = false;
    }
    document.body.removeChild(scratch);
    return ok;
  };

  const bindCopyFeedback = (btn, getText) => {
    if (btn.dataset.copyBound === "true") return;
    btn.dataset.copyBound = "true";
    const labelEl = btn.querySelector("[data-copy-label]");
    const initial = labelEl ? labelEl.textContent : btn.textContent;
    let timer = null;

    btn.addEventListener("click", async () => {
      const ok = await copyToClipboard(getText());
      if (labelEl) {
        labelEl.textContent = ok ? "Copied" : "Retry";
      } else {
        btn.textContent = ok ? "Copied" : "Retry";
      }
      if (timer) clearTimeout(timer);
      timer = setTimeout(() => {
        if (labelEl) {
          labelEl.textContent = initial;
        } else {
          btn.textContent = initial;
        }
      }, 1800);
    });
  };

  const initCopyButtons = () => {
    document.querySelectorAll("[data-copy-text]").forEach((btn) => {
      bindCopyFeedback(btn, () => btn.getAttribute("data-copy-text") || "");
    });

    document.querySelectorAll("[data-copy-target]").forEach((btn) => {
      bindCopyFeedback(btn, () => {
        const id = btn.getAttribute("data-copy-target");
        const target = id ? document.getElementById(id) : null;
        return target ? target.textContent || "" : "";
      });
    });

    // Inject copy buttons into article code blocks
    document.querySelectorAll(".prose-mahd pre").forEach((pre) => {
      if (pre.dataset.codeCopyBound === "true") return;
      pre.dataset.codeCopyBound = "true";

      const btn = document.createElement("button");
      btn.type = "button";
      btn.className =
        "no-print absolute top-2.5 right-2.5 px-2.5 py-1 rounded-[4px] border border-slate-700 bg-slate-900/90 hover:border-sky-400 text-slate-300 hover:text-sky-300 font-mono text-[11px] uppercase tracking-wider cursor-pointer transition-colors";
      btn.setAttribute("aria-label", "Copy code snippet");
      btn.textContent = "Copy";

      bindCopyFeedback(btn, () => {
        const code = pre.querySelector("code");
        return code ? code.textContent || "" : pre.textContent || "";
      });

      pre.appendChild(btn);
    });
  };

  const initMobileNav = () => {
    const btn = document.getElementById("mobile-menu-btn");
    const drawer = document.getElementById("mobile-nav-drawer");
    const label = document.getElementById("mobile-menu-label");
    if (!btn || !drawer || btn.dataset.navBound === "true") return;
    btn.dataset.navBound = "true";

    const setOpen = (open) => {
      btn.setAttribute("aria-expanded", String(open));
      drawer.classList.toggle("hidden", !open);
      if (label) label.textContent = open ? "Close" : "Menu";
    };

    btn.addEventListener("click", () => {
      setOpen(btn.getAttribute("aria-expanded") !== "true");
    });

    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape" && btn.getAttribute("aria-expanded") === "true") {
        setOpen(false);
        btn.focus();
      }
    });
  };

  const initBlogFiltering = () => {
    const searchInput = document.getElementById("blog-filter-input");
    const tagBtns = Array.from(document.querySelectorAll("[data-tag-filter]"));
    const cards = Array.from(document.querySelectorAll("[data-post-card]"));
    const statusEl = document.querySelector("[data-filter-status]");
    const emptyEl = document.getElementById("blog-empty-state");
    const resetBtn = document.getElementById("blog-reset-filter");
    const featuredWrap = document.querySelector("[data-featured-wrapper]");
    const archiveWrap = document.querySelector("[data-archive-wrapper]");

    if (cards.length === 0) return;

    let activeTag = "all";
    let query = "";

    const applyFilter = () => {
      let visibleCount = 0;
      const q = query.trim().toLowerCase();

      cards.forEach((card) => {
        const tags = (card.getAttribute("data-post-tags") || "")
          .split(",")
          .map((t) => t.trim())
          .filter(Boolean);
        const hay = card.getAttribute("data-post-search") || "";
        const tagMatch = activeTag === "all" || tags.includes(activeTag);
        const queryMatch = q === "" || hay.includes(q);
        const show = tagMatch && queryMatch;

        card.hidden = !show;
        if (show) visibleCount += 1;
      });

      if (featuredWrap) {
        const featCard = featuredWrap.querySelector("[data-post-card]");
        featuredWrap.hidden = Boolean(featCard && featCard.hidden);
      }

      if (archiveWrap) {
        const anyArchiveVisible = Array.from(
          archiveWrap.querySelectorAll("[data-post-card]")
        ).some((c) => !c.hidden);
        archiveWrap.hidden = !anyArchiveVisible;
      }

      if (emptyEl) {
        emptyEl.hidden = visibleCount > 0;
      }

      if (statusEl) {
        statusEl.textContent = `Showing ${visibleCount} of ${cards.length} dispatches`;
      }
    };

    const setTag = (tag) => {
      activeTag = tag;
      tagBtns.forEach((b) => {
        const selected = b.getAttribute("data-tag-filter") === tag;
        b.setAttribute("aria-pressed", String(selected));
        b.classList.toggle("border-accent-cyan", selected);
        b.classList.toggle("bg-surface-active", selected);
        b.classList.toggle("text-accent-cyan", selected);
        b.classList.toggle("font-semibold", selected);
        b.classList.toggle("border-border", !selected);
        b.classList.toggle("bg-well", !selected);
        b.classList.toggle("text-text-muted", !selected);
      });
      applyFilter();
    };

    tagBtns.forEach((b) => {
      b.addEventListener("click", () => {
        setTag(b.getAttribute("data-tag-filter") || "all");
      });
    });

    if (searchInput) {
      searchInput.addEventListener("input", () => {
        query = searchInput.value;
        applyFilter();
      });

      document.addEventListener("keydown", (e) => {
        if (
          e.key === "/" &&
          document.activeElement !== searchInput &&
          !["INPUT", "TEXTAREA"].includes(document.activeElement?.tagName || "")
        ) {
          e.preventDefault();
          searchInput.focus();
        }
      });
    }

    if (resetBtn) {
      resetBtn.addEventListener("click", () => {
        query = "";
        if (searchInput) searchInput.value = "";
        setTag("all");
      });
    }
  };

  const initGitHubComments = () => {
    const section = document.querySelector("[data-gh-comments-issue]");
    if (!section) return;
    const repo = section.getAttribute("data-gh-comments-repo");
    const issue = section.getAttribute("data-gh-comments-issue");
    const listEl = section.querySelector("[data-gh-comments-list]");
    if (!repo || !issue || !listEl) return;

    fetch(`https://api.github.com/repos/${repo}/issues/${encodeURIComponent(issue)}/comments`, {
      headers: { Accept: "application/vnd.github.v3+json" }
    })
      .then((res) => (res.ok ? res.json() : Promise.reject(new Error("unavailable"))))
      .then((comments) => {
        listEl.textContent = "";
        if (!Array.isArray(comments) || comments.length === 0) {
          const empty = document.createElement("p");
          empty.className = "font-mono text-xs text-text-muted";
          empty.textContent = "No comments posted yet. Join the thread on GitHub.";
          listEl.appendChild(empty);
          return;
        }

        comments.forEach((c) => {
          const card = document.createElement("article");
          card.className = "monolith-well p-4 space-y-2";

          const header = document.createElement("div");
          header.className = "flex items-center justify-between gap-2 font-mono text-xs";

          const author = document.createElement("a");
          author.href = c.user?.html_url || "#";
          author.target = "_blank";
          author.rel = "noopener noreferrer";
          author.className = "font-bold text-accent-cyan hover:underline";
          author.textContent = `@${c.user?.login || "user"}`;

          const time = document.createElement("time");
          time.className = "text-text-muted tabular-nums";
          time.textContent = String(c.created_at || "").slice(0, 10);

          const body = document.createElement("p");
          body.className = "text-sm text-text-primary whitespace-pre-line leading-relaxed";
          body.textContent = String(c.body || "");

          header.appendChild(author);
          header.appendChild(time);
          card.appendChild(header);
          card.appendChild(body);
          listEl.appendChild(card);
        });
      })
      .catch(() => {
        listEl.textContent = "";
        const msg = document.createElement("p");
        msg.className = "font-mono text-xs text-text-muted";
        msg.textContent = "Comments can be viewed and posted directly on GitHub.";
        listEl.appendChild(msg);
      });
  };

  document.addEventListener("DOMContentLoaded", () => {
    initThemeControls();
    initCopyButtons();
    initMobileNav();
    initBlogFiltering();
    initGitHubComments();
  });
})();
