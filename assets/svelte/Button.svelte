<script>
    export let variant = "primary";
    export let size = "md";
    export let disabled = false;
    export let loading = false;
    export let fullWidth = false;
    export let onClick = null;
    export let type = "button";

    const variantClasses = {
        primary: "btn-primary",
        secondary: "btn-secondary",
        accent: "btn-accent",
        ghost: "btn-ghost",
        outline: "btn-outline",
        error: "btn-error",
        warning: "btn-warning",
        info: "btn-info",
        success: "btn-success"
    };

    const sizeClasses = {
        xs: "btn-xs",
        sm: "btn-sm",
        md: "",
        lg: "btn-lg"
    };

    function handleClick(event) {
        if (!disabled && !loading && onClick) {
            onClick(event);
        }
    }
</script>

<button 
    {type}
    class="btn {variantClasses[variant]} {sizeClasses[size]} {fullWidth ? 'w-full' : ''}"
    class:loading
    disabled={disabled || loading}
    on:click={handleClick}
>
    {#if loading}
        <span class="loading loading-spinner loading-sm"></span>
    {/if}
    <slot />
</button> 