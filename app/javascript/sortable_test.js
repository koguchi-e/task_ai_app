import Sortable from "sortablejs";

document.addEventListener("DOMContentLoaded", () => {
  const element = document.querySelector("#sortable-list");
  const copyButton = document.querySelector("#copy-button");

  if (!element) return;

  Sortable.create(element);

  copyButton.addEventListener("click", () => {
    const items = document.querySelectorAll(".task-item");
    const markdown = Array.from(items)
      .map((item, index) => `${index + 1}. ${item.textContent.trim()}`)
      .join("\n");

    navigator.clipboard.writeText(markdown);
    alert("コピーしました");
  });
});
