const clock = document.querySelector("#clock");
const clockDate = document.querySelector("#clock-date");
function updateClock() {
  const now = new Date();
  clock.textContent = new Intl.DateTimeFormat("ja-JP", {hour:"2-digit",minute:"2-digit",second:"2-digit",hour12:false}).format(now);
  clock.dateTime = now.toISOString();
  clockDate.textContent = new Intl.DateTimeFormat("ja-JP", {year:"numeric",month:"long",day:"numeric",weekday:"long"}).format(now);
}
updateClock();
setInterval(updateClock, 1000);

const dialog = document.querySelector("#gallery-dialog");
const dialogImage = dialog.querySelector("img");
const dialogCaption = dialog.querySelector("p");
document.querySelectorAll(".gallery-item").forEach(item => item.addEventListener("click", () => {
  dialogImage.src = item.dataset.image;
  dialogImage.alt = item.querySelector("img").alt;
  dialogCaption.textContent = item.dataset.caption;
  dialog.showModal();
}));
dialog.querySelector(".dialog-close").addEventListener("click", () => dialog.close());
dialog.addEventListener("click", event => { if (event.target === dialog) dialog.close(); });
