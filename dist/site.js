const introScreen = document.querySelector(".intro-screen");
if (introScreen) {
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const finishIntro = () => {
    document.body.classList.remove("intro-active");
    introScreen.remove();
  };
  window.setTimeout(finishIntro, reducedMotion ? 2300 : 5200);
}

const clock = document.querySelector("#clock");
const face = document.querySelector("#clock-face");
const svgNS = "http://www.w3.org/2000/svg";
const points = [
  "3,0 17,0 19,2 17,4 3,4 1,2",
  "17,3 19,1 21,3 21,15 19,17 17,15",
  "17,20 19,18 21,20 21,33 19,35 17,33",
  "3,32 17,32 19,34 17,36 3,36 1,34",
  "0,20 2,18 4,20 4,33 2,35 0,33",
  "0,3 2,1 4,3 4,15 2,17 0,15",
  "3,16 17,16 19,18 17,20 3,20 1,18"
];
const masks = ["abcdef","bc","abdeg","abcdg","bcfg","acdfg","acdefg","abc","abcdefg","abcdfg"];
const on = "#e7f4ff";
const off = "rgba(38,52,62,.26)";
function svgElement(name, attributes = {}) {
  const element = document.createElementNS(svgNS, name);
  for (const [key, value] of Object.entries(attributes)) element.setAttribute(key, value);
  return element;
}
face.append(svgElement("rect", {x:0,y:0,width:154,height:40,rx:3,fill:"rgba(0,0,0,.70)"}));
const digits = [];
for (const [x,y,size] of [[0,0,1],[24,0,1],[57,0,1],[81,0,1],[109,16,.55],[123,16,.55]]) {
  const group = svgElement("g", {transform:`translate(${x+2} ${y+2}) scale(${size})`});
  const segments = points.map(shape => {
    const polygon = svgElement("polygon", {points:shape,fill:off});
    group.append(polygon);
    return polygon;
  });
  face.append(group);
  digits.push(segments);
}
for (const y of [9,24]) face.append(svgElement("polygon", {points:"1,0 3,0 4,2 3,4 1,4 0,2",transform:`translate(52 ${y+2})`,fill:on}));
function updateClock() {
  const now = new Date();
  const value = [now.getHours(),now.getMinutes(),now.getSeconds()].map(part => String(part).padStart(2,"0")).join(":");
  clock.textContent = value;
  clock.dateTime = now.toISOString();
  [...value.replaceAll(":","")].forEach((character,index) => {
    const mask = masks[Number(character)];
    digits[index].forEach((segment,segmentIndex) => segment.setAttribute("fill",mask.includes("abcdefg"[segmentIndex]) ? on : off));
  });
}
updateClock();
setInterval(updateClock, 1000);
const preview = document.querySelector(".clock-real");
let zoom = 1.25;
function resizePreview(change) {
  zoom = Math.max(1,Math.min(1.5,zoom + change));
  preview.style.setProperty("--zoom",zoom);
  preview.querySelector(".clock-plus").disabled = zoom >= 1.5;
  preview.querySelector(".clock-minus").disabled = zoom <= 1;
}
preview.querySelector(".clock-plus").addEventListener("click", () => resizePreview(.25));
preview.querySelector(".clock-minus").addEventListener("click", () => resizePreview(-.25));
resizePreview(0);

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
