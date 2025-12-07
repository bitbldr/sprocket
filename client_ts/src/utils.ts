export const isInteger = (str) => !Number.isNaN(parseInt(str, 10));

export function htmlDecode(str: string) {
  var doc = new DOMParser().parseFromString(str, "text/html");
  return doc.documentElement.textContent;
}
