export const isInteger = (str) => !Number.isNaN(parseInt(str, 10));

export function htmlDecode(str: string) {
  let doc = new DOMParser().parseFromString(str, "text/html");
  return doc.documentElement.textContent;
}

export function debounce(func, wait, immediate) {
  let timeout;
  return function () {
    let context = this,
      args = arguments;
    clearTimeout(timeout);
    if (immediate && !timeout) func.apply(context, args);
    timeout = setTimeout(function () {
      timeout = null;
      if (!immediate) func.apply(context, args);
    }, wait);
  };
}

export function throttle(func, timeFrame) {
  let lastTime: any = 0;
  return function (...args) {
    let now: any = new Date();
    if (now - lastTime >= timeFrame) {
      func(...args);
      lastTime = now;
    }
  };
}
