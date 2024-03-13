function updateInnerHtml (oldVNode, vNode) {
    const {data: oldData = {}} = oldVNode
    const {data = {}, elm} = vNode
    const html = data.innerHtml || false
    
    if (!html) return
    
    if (html && oldData.innerHtml !== html) {
      elm.innerHTML = html
    }
  }
  
  export const rawHtmlModule = {
    create: updateInnerHtml,
    update: updateInnerHtml,
  }