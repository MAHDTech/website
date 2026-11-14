(() => {
  "use strict";

  /* ------------------------------------------------------------------------
     Theme: "system" (no stored value) or an explicit "light" / "dark".
     The choice is applied through <meta name="color-scheme">; the inline
     script in partials/head.html applies a stored choice before first paint.
     ---------------------------------------------------------------------- */
  const STORAGE_KEY = "color-scheme";
  const darkQuery = window.matchMedia("(prefers-color-scheme: dark)");

  const getSystemScheme = () => (darkQuery.matches ? "dark" : "light");

  const getStoredScheme = () => {
    try {
      const val = localStorage.getItem(STORAGE_KEY);
      return val === "light" || val === "dark" ? val : null;
    } catch {
      return null;
    }
  };

  const applyThemeState = (override) => {
    const meta = document.querySelector('meta[name="color-scheme"]');
    if (meta) meta.content = override ?? "light dark";

    const label = override
      ? override === "dark" ? "Dark" : "Light"
      : `Auto · ${getSystemScheme() === "dark" ? "Dark" : "Light"}`;

    document.querySelectorAll("[data-theme-toggle]").forEach((btn) => {
      btn.querySelector('[data-theme-icon="sun"]')?.classList.toggle("hidden", override !== "light");
      btn.querySelector('[data-theme-icon="moon"]')?.classList.toggle("hidden", override !== "dark");
      btn.querySelector('[data-theme-icon="auto"]')?.classList.toggle("hidden", override !== null);
      const labelEl = btn.querySelector("[data-theme-label]");
      if (labelEl) labelEl.textContent = label;
    });

    document.querySelectorAll("[data-theme-choice]").forEach((btn) => {
      const choice = btn.getAttribute("data-theme-choice");
      btn.setAttribute("aria-pressed", String(choice === (override ?? "system")));
    });
  };

  const setThemeChoice = (choice) => {
    const override = choice === "light" || choice === "dark" ? choice : null;
    try {
      if (override) localStorage.setItem(STORAGE_KEY, override);
      else localStorage.removeItem(STORAGE_KEY);
    } catch {}
    applyThemeState(override);
  };

  // The header button flips to the opposite of what is shown. Landing on the
  // system preference clears the override so auto-detection resumes.
  const toggleTheme = () => {
    const rendered = getStoredScheme() ?? getSystemScheme();
    const target = rendered === "dark" ? "light" : "dark";
    setThemeChoice(target === getSystemScheme() ? "system" : target);
  };

  const initTheme = () => {
    applyThemeState(getStoredScheme());
    document.querySelectorAll("[data-theme-toggle]").forEach((btn) => btn.addEventListener("click", toggleTheme));
    document.querySelectorAll("[data-theme-choice]").forEach((btn) =>
      btn.addEventListener("click", () => setThemeChoice(btn.getAttribute("data-theme-choice")))
    );
    darkQuery.addEventListener("change", () => applyThemeState(getStoredScheme()));
    window.addEventListener("storage", (event) => {
      if (event.key === STORAGE_KEY) applyThemeState(getStoredScheme());
    });
  };

  /* ------------------------------------------------------------------------
     Clipboard
     ---------------------------------------------------------------------- */
  const copyToClipboard = async (text) => {
    try {
      await navigator.clipboard.writeText(String(text ?? ""));
      return true;
    } catch {
      return false;
    }
  };

  const bindCopyFeedback = (btn, getText) => {
    const labelEl = btn.querySelector("[data-copy-label]") ?? btn;
    const initial = labelEl.textContent;
    let timer = null;
    btn.addEventListener("click", async () => {
      labelEl.textContent = (await copyToClipboard(getText())) ? "Copied" : "Copy failed";
      clearTimeout(timer);
      timer = setTimeout(() => (labelEl.textContent = initial), 1800);
    });
  };

  const initCopyButtons = () => {
    document.querySelectorAll("[data-copy-text]").forEach((btn) =>
      bindCopyFeedback(btn, () => btn.getAttribute("data-copy-text"))
    );
    document.querySelectorAll("[data-copy-target]").forEach((btn) =>
      bindCopyFeedback(btn, () => document.getElementById(btn.getAttribute("data-copy-target"))?.textContent ?? "")
    );

    document.querySelectorAll(".prose-mahd pre").forEach((pre) => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className =
        "no-print absolute top-2.5 right-2.5 px-2.5 py-1 rounded-[4px] border border-slate-700 bg-slate-900/90 hover:border-sky-400 text-slate-300 hover:text-sky-300 font-mono text-[11px] cursor-pointer transition-colors";
      btn.setAttribute("aria-label", "Copy code");
      btn.textContent = "Copy";
      bindCopyFeedback(btn, () => (pre.querySelector("code") ?? pre).textContent);
      pre.appendChild(btn);
    });
  };

  /* ------------------------------------------------------------------------
     Mobile navigation
     ---------------------------------------------------------------------- */
  const initMobileNav = () => {
    const btn = document.getElementById("mobile-menu-btn");
    const drawer = document.getElementById("mobile-nav-drawer");
    const label = document.getElementById("mobile-menu-label");
    if (!btn || !drawer) return;

    const setOpen = (open) => {
      btn.setAttribute("aria-expanded", String(open));
      drawer.classList.toggle("hidden", !open);
      if (label) label.textContent = open ? "Close" : "Menu";
    };

    btn.addEventListener("click", () => setOpen(btn.getAttribute("aria-expanded") !== "true"));
    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape" && btn.getAttribute("aria-expanded") === "true") {
        setOpen(false);
        btn.focus();
      }
    });
  };

  /* ------------------------------------------------------------------------
     Blog index filters (only rendered once there are enough posts)
     ---------------------------------------------------------------------- */
  const initBlogFiltering = () => {
    const searchInput = document.getElementById("blog-filter-input");
    const tagBtns = Array.from(document.querySelectorAll("[data-tag-filter]"));
    const cards = Array.from(document.querySelectorAll("[data-post-card]"));
    if (!searchInput || cards.length === 0) return;

    const statusEl = document.querySelector("[data-filter-status]");
    const emptyEl = document.getElementById("blog-empty-state");
    const featuredWrap = document.querySelector("[data-featured-wrapper]");
    const archiveWrap = document.querySelector("[data-archive-wrapper]");
    let activeTag = "all";

    const applyFilter = () => {
      const q = searchInput.value.trim().toLowerCase();
      let visible = 0;
      cards.forEach((card) => {
        const tags = (card.getAttribute("data-post-tags") || "").split(",");
        const show =
          (activeTag === "all" || tags.includes(activeTag)) &&
          (q === "" || (card.getAttribute("data-post-search") || "").includes(q));
        card.hidden = !show;
        if (show) visible += 1;
      });
      if (featuredWrap) featuredWrap.hidden = Boolean(featuredWrap.querySelector("[data-post-card]")?.hidden);
      if (archiveWrap) archiveWrap.hidden = !Array.from(archiveWrap.querySelectorAll("[data-post-card]")).some((c) => !c.hidden);
      if (emptyEl) emptyEl.hidden = visible > 0;
      if (statusEl) statusEl.textContent = `Showing ${visible} of ${cards.length} posts`;
    };

    const setTag = (tag) => {
      activeTag = tag;
      tagBtns.forEach((b) => b.setAttribute("aria-pressed", String(b.getAttribute("data-tag-filter") === tag)));
      applyFilter();
    };

    tagBtns.forEach((b) => b.addEventListener("click", () => setTag(b.getAttribute("data-tag-filter") || "all")));
    searchInput.addEventListener("input", applyFilter);
    document.getElementById("blog-reset-filter")?.addEventListener("click", () => {
      searchInput.value = "";
      setTag("all");
    });
    applyFilter();
  };

  /* ------------------------------------------------------------------------
     Command palette (Ctrl/Cmd+K or "/")
     Static entries come from partials/command_palette.html. Full-text results
     come from the Pagefind index, loaded the first time someone types.
     ---------------------------------------------------------------------- */
  const initCommandPalette = () => {
    const dialog = document.getElementById("command-palette");
    const input = document.getElementById("palette-input");
    const list = document.getElementById("palette-list");
    if (!dialog || !input || !list) return;

    const emptyEl = dialog.querySelector("[data-palette-empty]");
    const fulltextHeading = list.querySelector("[data-palette-fulltext]");
    const staticItems = Array.from(list.querySelectorAll("[data-palette-item]"));
    staticItems.forEach((el, i) => {
      el.id = `palette-item-${i}`;
      el.dataset.haystack = `${el.textContent} ${el.dataset.keywords || ""}`.toLowerCase();
    });

    const isMac = /Mac|iPhone|iPad/.test(navigator.platform || navigator.userAgent);
    document.querySelectorAll("[data-palette-shortcut]").forEach((el) => (el.textContent = isMac ? "⌘K" : "Ctrl K"));

    let pagefind = null;
    let pagefindFailed = false;
    let searchSeq = 0;
    let active = -1;

    const visibleItems = () => Array.from(list.querySelectorAll("[data-palette-item]:not([hidden])"));

    const setActive = (index) => {
      const items = visibleItems();
      items.forEach((el) => el.setAttribute("aria-selected", "false"));
      active = items.length === 0 ? -1 : (index + items.length) % items.length;
      const current = items[active];
      if (current) {
        current.setAttribute("aria-selected", "true");
        current.scrollIntoView({ block: "nearest" });
        input.setAttribute("aria-activedescendant", current.id);
      } else {
        input.removeAttribute("aria-activedescendant");
      }
    };

    // Hide group headings that have no visible items beneath them.
    const syncGroups = () => {
      let heading = null;
      let count = 0;
      const flush = () => {
        if (heading && !heading.hasAttribute("data-palette-fulltext")) heading.hidden = count === 0;
      };
      Array.from(list.children).forEach((el) => {
        if (el.hasAttribute("data-palette-group")) {
          flush();
          heading = el;
          count = 0;
        } else if (!el.hidden) {
          count += 1;
        }
      });
      flush();
      if (emptyEl) emptyEl.hidden = visibleItems().length > 0;
    };

    const loadPagefind = async () => {
      if (pagefind || pagefindFailed) return pagefind;
      try {
        // Resolve against the page, not this script: in development the script
        // can load from 127.0.0.1 while the page is on localhost.
        pagefind = await import(new URL("/pagefind/pagefind.js", location.origin).href);
        await pagefind.init?.();
      } catch {
        pagefindFailed = true; // Index not built yet (run `generate`); static entries still work.
      }
      return pagefind;
    };

    // Pagefind excerpts are entity-escaped text with <mark> highlights. Keep the
    // highlights as real elements and treat everything else as plain text.
    const decode = (html) => new DOMParser().parseFromString(html, "text/html").body.textContent ?? "";
    const excerptNodes = (html) => {
      let inMark = false;
      return String(html || "")
        .split(/(<mark>|<\/mark>)/)
        .flatMap((part) => {
          if (part === "<mark>" || part === "</mark>") {
            inMark = part === "<mark>";
            return [];
          }
          if (!part) return [];
          const text = decode(part);
          return inMark ? [Object.assign(document.createElement("mark"), { textContent: text })] : [document.createTextNode(text)];
        });
    };

    const clearFulltext = () => {
      list.querySelectorAll("[data-palette-result]").forEach((el) => el.remove());
      if (fulltextHeading) fulltextHeading.hidden = true;
    };

    const runFulltext = async (query) => {
      const seq = ++searchSeq;
      if (query.length < 2) {
        clearFulltext();
        return;
      }
      const pf = await loadPagefind();
      if (!pf || seq !== searchSeq) return;
      const search = await pf.debouncedSearch(query, {}, 150);
      if (!search || seq !== searchSeq) return;
      const results = await Promise.all(search.results.slice(0, 6).map((r) => r.data()));
      if (seq !== searchSeq) return;

      clearFulltext();
      const staticHrefs = new Set(
        staticItems.filter((el) => !el.hidden).map((el) => new URL(el.dataset.href || "#", location.href).pathname)
      );
      results
        .filter((r) => !staticHrefs.has(new URL(r.url, location.href).pathname))
        .forEach((r, i) => {
          const li = document.createElement("li");
          li.setAttribute("role", "option");
          li.id = `palette-result-${i}`;
          li.dataset.paletteItem = "";
          li.dataset.paletteResult = "";
          li.dataset.href = r.url;
          const title = document.createElement("span");
          title.textContent = r.meta?.title || r.url;
          const excerpt = document.createElement("span");
          excerpt.className = "palette-excerpt";
          excerpt.append(...excerptNodes(r.excerpt));
          li.append(title, excerpt);
          list.appendChild(li);
        });
      if (fulltextHeading) fulltextHeading.hidden = !list.querySelector("[data-palette-result]");
      syncGroups();
      if (active === -1) setActive(0);
    };

    const filter = () => {
      const q = input.value.trim().toLowerCase();
      const terms = q.split(/\s+/).filter(Boolean);
      staticItems.forEach((el) => {
        el.hidden = !terms.every((t) => el.dataset.haystack.includes(t));
      });
      syncGroups();
      setActive(0);
      runFulltext(q);
    };

    const activate = async (el) => {
      if (!el) return;
      const { href, copy, themeSet, download } = el.dataset;
      if (themeSet) {
        setThemeChoice(themeSet);
      } else if (copy) {
        const ok = await copyToClipboard(copy);
        const original = el.textContent;
        el.textContent = ok ? "Copied!" : "Copy failed";
        setTimeout(() => (el.textContent = original), 1200);
        return;
      } else if (download) {
        const a = Object.assign(document.createElement("a"), { href, download });
        a.click();
      } else if (href) {
        if (el.hasAttribute("data-external")) window.open(href, "_blank", "noopener");
        else location.href = href;
      }
      dialog.close();
    };

    const open = () => {
      if (dialog.open) return;
      input.value = "";
      filter();
      dialog.showModal();
      input.focus();
      loadPagefind();
    };

    document.querySelectorAll("[data-palette-open]").forEach((btn) => btn.addEventListener("click", open));

    document.addEventListener("keydown", (event) => {
      const typing = ["INPUT", "TEXTAREA", "SELECT"].includes(document.activeElement?.tagName) || document.activeElement?.isContentEditable;
      if ((event.key === "k" || event.key === "K") && (event.metaKey || event.ctrlKey)) {
        event.preventDefault();
        dialog.open ? dialog.close() : open();
      } else if (event.key === "/" && !typing && !dialog.open) {
        event.preventDefault();
        open();
      }
    });

    input.addEventListener("input", filter);
    input.addEventListener("keydown", (event) => {
      if (event.key === "ArrowDown") {
        event.preventDefault();
        setActive(active + 1);
      } else if (event.key === "ArrowUp") {
        event.preventDefault();
        setActive(active - 1);
      } else if (event.key === "Enter") {
        event.preventDefault();
        activate(visibleItems()[active]);
      }
    });

    list.addEventListener("click", (event) => activate(event.target.closest("[data-palette-item]")));
    list.addEventListener("mousemove", (event) => {
      const item = event.target.closest("[data-palette-item]");
      if (item) setActive(visibleItems().indexOf(item));
    });
    dialog.addEventListener("click", (event) => {
      if (event.target === dialog) dialog.close();
    });
  };

  /* ------------------------------------------------------------------------
     GitHub issue comments (posts with extra.github_issue_id)
     ---------------------------------------------------------------------- */
  const initGitHubComments = () => {
    const section = document.querySelector("[data-gh-comments-issue]");
    const listEl = section?.querySelector("[data-gh-comments-list]");
    if (!section || !listEl) return;
    const repo = section.getAttribute("data-gh-comments-repo");
    const issue = encodeURIComponent(section.getAttribute("data-gh-comments-issue"));

    const message = (text) => {
      const p = document.createElement("p");
      p.className = "text-xs text-text-muted";
      p.textContent = text;
      listEl.replaceChildren(p);
    };

    fetch(`https://api.github.com/repos/${repo}/issues/${issue}/comments`, {
      headers: { Accept: "application/vnd.github+json" },
    })
      .then((res) => (res.ok ? res.json() : Promise.reject(new Error(String(res.status)))))
      .then((comments) => {
        if (!Array.isArray(comments) || comments.length === 0) {
          message("No comments yet. Start the conversation on GitHub.");
          return;
        }
        listEl.replaceChildren(
          ...comments.map((c) => {
            const card = document.createElement("article");
            card.className = "monolith-well p-4 space-y-2";
            const header = document.createElement("div");
            header.className = "flex items-center justify-between gap-2 text-xs";
            const author = Object.assign(document.createElement("a"), {
              href: c.user?.html_url || "#",
              target: "_blank",
              rel: "noopener noreferrer",
              className: "font-semibold text-accent-cyan hover:underline",
              textContent: `@${c.user?.login || "user"}`,
            });
            const time = Object.assign(document.createElement("time"), {
              className: "text-text-muted tabular-nums",
              dateTime: c.created_at || "",
              textContent: String(c.created_at || "").slice(0, 10),
            });
            const body = Object.assign(document.createElement("p"), {
              className: "text-sm text-text-primary whitespace-pre-line leading-relaxed",
              textContent: String(c.body || ""),
            });
            header.append(author, time);
            card.append(header, body);
            return card;
          })
        );
      })
      .catch(() => message("Comments couldn't be loaded here. You can read and post them on GitHub."));
  };

  document.addEventListener("DOMContentLoaded", () => {
    initTheme();
    initCopyButtons();
    initMobileNav();
    initBlogFiltering();
    initCommandPalette();
    initGitHubComments();
  });
})();
