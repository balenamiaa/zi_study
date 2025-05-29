<script>
    import { onMount } from "svelte";
    import AvatarUploadModal from "./AvatarUploadModal.svelte";

    let {
        live,
        currentUrl = null,
        size = "md",
        disabled = false,
        children,
    } = $props();

    let modalOpen = $state(false);
    let hover = $state(false);

    const sizeClasses = {
        sm: "w-16 h-16",
        md: "w-24 h-24",
        lg: "w-32 h-32",
    };

    const iconSizes = {
        sm: "w-5 h-5",
        md: "w-7 h-7",
        lg: "w-9 h-9",
    };

    function openModal() {
        if (!disabled) {
            modalOpen = true;
        }
    }

    function closeModal() {
        modalOpen = false;
    }

    onMount(() => {});
</script>

<div class="relative inline-block group">
    <!-- Avatar display -->
    <div
        class="{sizeClasses[
            size
        ]} rounded-full overflow-hidden border-2 transition-all duration-300 cursor-pointer
               {hover ? 'border-primary shadow-md' : 'border-base-300'}
               {disabled ? 'opacity-60 cursor-not-allowed' : ''}"
        onmouseenter={() => (hover = true)}
        onmouseleave={() => (hover = false)}
        onclick={openModal}
        onkeydown={(e) => e.key === "Enter" && openModal()}
        role="button"
        tabindex="0"
    >
        {#if currentUrl}
            <img
                src={currentUrl}
                alt="Profile avatar"
                class="w-full h-full object-cover transition-transform duration-300 {hover
                    ? 'scale-105'
                    : ''}"
            />
        {:else}
            <div
                class="w-full h-full flex items-center justify-center bg-gradient-to-br from-base-200 to-base-300"
            >
                <svg
                    class="{iconSizes[size]} text-base-content/50"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                    />
                </svg>
            </div>
        {/if}
    </div>

    <!-- Edit overlay that appears on hover -->
    {#if !disabled}
        <div
            class="absolute inset-0 rounded-full flex items-center justify-center
                   bg-black/40 opacity-0 group-hover:opacity-100
                   transition-all duration-300 cursor-pointer
                   border-2 border-primary"
            onclick={openModal}
            onkeydown={(e) => e.key === "Enter" && openModal()}
            role="button"
            tabindex="0"
            aria-label="Change profile picture"
        >
            <div
                class="text-white text-xs font-medium tracking-wide flex flex-col items-center justify-center gap-1"
            >
                <svg
                    class="{iconSizes[size]} mb-1"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"
                    />
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M15 13a3 3 0 11-6 0 3 3 0 016 0z"
                    />
                </svg>
                <span>Change</span>
            </div>
        </div>
    {/if}
</div>

<!-- Upload modal -->
<AvatarUploadModal
    {live}
    isOpen={modalOpen}
    onClose={closeModal}
    initialImageUrl={currentUrl}
>
    {#if children}
        {@render children()}
    {/if}
</AvatarUploadModal>
