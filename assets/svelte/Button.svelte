<script>
    import { twMerge } from "tailwind-merge";

    let {
        variant = "primary", // 'primary', 'secondary', 'accent', 'ghost', 'link', 'outline', 'error', 'warning', 'info', 'success'
        size = "md", // 'xs', 'sm', 'md', 'lg'
        disabled = false,
        loading = false,
        fullWidth = false,
        type = "button", // 'button', 'submit', 'reset'
        spinnerSize = "sm", // Size of the DaisyUI spinner: 'xs', 'sm', 'md', 'lg'
        class: userClass = "",
        children,
        ...restProps
    } = $props();

    const variantMap = {
        primary: "btn-primary",
        secondary: "btn-secondary",
        accent: "btn-accent",
        ghost: "btn-ghost",
        link: "btn-link",
        outline: "btn-outline",
        error: "btn-error",
        warning: "btn-warning",
        info: "btn-info",
        success: "btn-success",
    };

    const sizeMap = {
        xs: "btn-xs",
        sm: "btn-sm",
        md: "", // Default DaisyUI button size, no specific class (btn-md doesn't exist)
        lg: "btn-lg",
    };

    const spinnerSizeMap = {
        xs: "loading-xs",
        sm: "loading-sm",
        md: "loading-md", // Default DaisyUI spinner size if no class specified on spinner
        lg: "loading-lg",
    };

    // Svelte 5: Use $derived for reactive class computation, merged with twMerge
    const computedButtonClasses = $derived(
        twMerge(
            "btn", // Base DaisyUI button class
            variantMap[variant], // Variant class
            sizeMap[size], // Size class
            fullWidth && "w-full", // Full width utility
            userClass, // User-provided classes
        ),
    );

    const computedSpinnerClasses = $derived(
        twMerge(
            "loading",
            "loading-bars",
            spinnerSizeMap[spinnerSize] || spinnerSizeMap.sm,
        ),
    );
</script>

<button
    {type}
    class={computedButtonClasses}
    disabled={disabled || loading}
    {...restProps}
>
    {#if loading}
        <span class={computedSpinnerClasses}></span>
    {/if}

    {#if children}
        {@render children()}
    {/if}
</button>
