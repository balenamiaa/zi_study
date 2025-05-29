<script>
    let {
        isOpen,
        onClose,
        title = "",
        size = "md",
        closeOnOverlayClick = true,
        showCloseButton = true,
        children,
    } = $props();

    const sizeClasses = {
        sm: "modal-box w-11/12 max-w-sm",
        md: "modal-box w-11/12 max-w-md",
        lg: "modal-box w-11/12 max-w-lg",
        xl: "modal-box w-11/12 max-w-xl",
    };

    function handleOverlayClick(event) {
        if (closeOnOverlayClick && event.target === event.currentTarget) {
            onClose?.();
        }
    }

    function handleKeyDown(event) {
        if (event.key === "Escape" && closeOnOverlayClick) {
            onClose?.();
        }
    }
</script>

<svelte:window on:keydown={handleKeyDown} />

{#if isOpen}
    <div
        class="modal modal-open"
        onclick={handleOverlayClick}
        onkeydown={handleKeyDown}
        role="dialog"
        aria-modal="true"
        tabindex="0"
        aria-labelledby={title ? "modal-title" : undefined}
    >
        <div class={sizeClasses[size]}>
            {#if title || showCloseButton}
                <div class="flex items-center justify-between mb-4">
                    {#if title}
                        <h3 id="modal-title" class="font-bold text-lg">
                            {title}
                        </h3>
                    {:else}
                        <div></div>
                    {/if}

                    {#if showCloseButton}
                        <button
                            class="btn btn-sm btn-circle btn-ghost"
                            onclick={onClose}
                            aria-label="Close modal"
                        >
                            <svg
                                class="w-6 h-6"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M6 18L18 6M6 6l12 12"
                                />
                            </svg>
                        </button>
                    {/if}
                </div>
            {/if}

            <div class="modal-content">
                {#if children}
                    {@render children()}
                {/if}
            </div>
        </div>
    </div>
{/if}
