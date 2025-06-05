/**
 * Portal action - renders an element outside of its normal DOM tree
 * @param {HTMLElement} node - The element to portal
 * @param {HTMLElement|string} target - Target element or selector (defaults to document.body)
 * @returns {object} Action object with update and destroy methods
 */
export function portal(node, target = document.body) {
    let targetEl;
    let originalParent = node.parentNode;
    let originalNextSibling = node.nextSibling;

    function update(newTarget) {
        target = newTarget;

        if (typeof target === 'string') {
            targetEl = document.querySelector(target);
        } else if (target instanceof HTMLElement) {
            targetEl = target;
        } else {
            targetEl = document.body;
        }

        if (targetEl && node.parentNode !== targetEl) {
            targetEl.appendChild(node);
        }
    }

    function destroy() {
        if (node.parentNode) {
            if (originalParent && originalParent.contains && !originalParent.contains(node)) {
                if (originalNextSibling && originalNextSibling.parentNode === originalParent) {
                    originalParent.insertBefore(node, originalNextSibling);
                } else {
                    originalParent.appendChild(node);
                }
            } else {
                node.parentNode.removeChild(node);
            }
        }
    }

    update(target);

    return {
        update,
        destroy
    };
} 