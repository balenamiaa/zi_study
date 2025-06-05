<script>
    import { portal } from '../utils/portal.js';

    let {
        isOpen,
        onClose,
        title = "",
        size = "md",
        closeOnOverlayClick = true,
        showCloseButton = true,
        children,
    } = $props();

    const modalId = `modal-${Math.random().toString(36).substr(2, 9)}`;

    let dialogEl;

    const sizeClasses = {
        sm: "modal-box w-11/12 max-w-sm",
        md: "modal-box w-11/12 max-w-md",
        lg: "modal-box w-11/12 max-w-lg",
        xl: "modal-box w-11/12 max-w-xl",
    };

    $effect(() => {
        if (dialogEl) {
            if (isOpen && !dialogEl.open) {
                dialogEl.showModal();
            } else if (!isOpen && dialogEl.open) {
                dialogEl.close();
            }
        }
    });

    function handleOverlayClick(event) {
        if (closeOnOverlayClick && event.target === dialogEl) {
            onClose?.();
        }
    }
</script>

<dialog
    bind:this={dialogEl}
    class="modal"
    onclick={handleOverlayClick}
    aria-labelledby={title ? modalId : undefined}
    aria-modal="true"
    tabindex="0"
    use:portal
    style:display={isOpen ? "flex" : "none"}
    style:align-items="center"
    style:justify-content="center"
    style:position="fixed"
    style:inset="0"
    style:z-index="999"
>
    <div class={sizeClasses[size]}>
        {#if title || showCloseButton}
            <div class="flex items-center justify-between mb-4">
                {#if title}
                    <h3 id={modalId} class="font-bold text-lg">
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
</dialog>
