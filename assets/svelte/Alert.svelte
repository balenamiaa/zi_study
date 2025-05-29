<script>
    export let variant = "info";
    export let dismissible = false;
    export let onDismiss = null;

    const variantClasses = {
        info: "alert-info",
        success: "alert-success",
        warning: "alert-warning",
        error: "alert-error"
    };

    const iconPaths = {
        info: "M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
        success: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z",
        warning: "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z",
        error: "M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"
    };

    function handleDismiss() {
        if (onDismiss) {
            onDismiss();
        }
    }
</script>

<div class="alert {variantClasses[variant]}">
    <svg class="stroke-current shrink-0 w-6 h-6" fill="none" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={iconPaths[variant]} />
    </svg>
    
    <div class="flex-1">
        <slot />
    </div>
    
    {#if dismissible}
        <button 
            class="btn btn-sm btn-circle btn-ghost"
            on:click={handleDismiss}
            aria-label="Dismiss alert"
        >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
        </button>
    {/if}
</div> 