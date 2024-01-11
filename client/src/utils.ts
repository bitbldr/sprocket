export const isInteger = (str) => !Number.isNaN(parseInt(str, 10));

export function htmlDecode(input) {
  var doc = new DOMParser().parseFromString(input, "text/html");
  return doc.documentElement.textContent;
}
