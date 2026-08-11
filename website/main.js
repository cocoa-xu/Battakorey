document.documentElement.classList.add("js");

const navToggle = document.querySelector(".nav-toggle");
const navMenu = document.querySelector(".nav-menu");

navToggle?.addEventListener("click", () => {
  const isOpen = navToggle.getAttribute("aria-expanded") === "true";
  navToggle.setAttribute("aria-expanded", String(!isOpen));
  navMenu?.classList.toggle("is-open", !isOpen);
});

navMenu?.querySelectorAll("a").forEach((link) => {
  link.addEventListener("click", () => {
    navToggle?.setAttribute("aria-expanded", "false");
    navMenu.classList.remove("is-open");
  });
});

const tourCanvas = document.querySelector(".tour-canvas");
const tourImage = document.querySelector(".tour-image");
const tourTabs = document.querySelectorAll(".tour-tabs [role='tab']");

tourTabs.forEach((tab) => {
  tab.addEventListener("click", () => {
    if (
      tab.getAttribute("aria-selected") === "true" ||
      !tourImage ||
      !tourCanvas
    )
      return;

    tourTabs.forEach((item) =>
      item.setAttribute("aria-selected", String(item === tab)),
    );
    tourImage.classList.add("is-changing");

    window.setTimeout(() => {
      tourImage.src = tab.dataset.image ?? "";
      tourImage.alt = tab.dataset.alt ?? "Battakorey screenshot";
      tourCanvas.dataset.previewKind = tab.dataset.kind ?? "menu";
      tourImage.classList.remove("is-changing");
    }, 160);
  });
});

const revealObserver = new IntersectionObserver(
  (entries, observer) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      entry.target.classList.add("is-visible");
      observer.unobserve(entry.target);
    });
  },
  { threshold: 0.12 },
);

document
  .querySelectorAll("[data-reveal]")
  .forEach((element) => revealObserver.observe(element));

const year = document.querySelector("#year");
if (year) year.textContent = String(new Date().getFullYear());
