<script>
    import MarkdownContent from "../MarkdownContent.svelte";
    
    let { explanation, class: userClass = "" } = $props();
</script>

<div class="mt-3 p-3 bg-base-100 border border-base-300 rounded-lg {userClass}">
    <div class="flex items-start gap-2">
        <svg class="w-4 h-4 text-info mt-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <div>
            <div class="text-xs font-medium text-info uppercase tracking-wide">Explanation</div>
            <MarkdownContent content={explanation} cssClass="text-sm text-base-content mt-1 prose prose-sm max-w-none" />
        </div>
    </div>
</div> 