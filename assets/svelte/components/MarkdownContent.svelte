<script>
    import { parseMarkdown } from "../utils/markdown.js";

    let { content, cssClass = "" } = $props();

    let htmlContent = $derived(parseMarkdown(content));
</script>

<div class={cssClass}>
    {@html htmlContent}
</div>
