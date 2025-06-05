<script>
    import { twMerge } from "tailwind-merge";

    let {
        variant = "primary",
        size = "md",
        disabled = false,
        loading = false,
        fullWidth = false,
        type = "button",
        spinnerSize = "sm",
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
        md: "",
        lg: "btn-lg",
    };

    const spinnerSizeMap = {
        xs: "loading-xs",
        sm: "loading-sm",
        md: "loading-md",
        lg: "loading-lg",
    };

    const computedButtonClasses = $derived(
        twMerge(
            "btn",
            variantMap[variant],
            sizeMap[size],
            fullWidth && "w-full",
            userClass,
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
