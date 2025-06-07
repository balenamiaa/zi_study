<script>
    let {
        variant = "neutral",
        size = "md",
        class: userClass = "",
        children
    } = $props();

    const variantClasses = {
        neutral: "badge-neutral",
        primary: "badge-primary",
        secondary: "badge-secondary",
        accent: "badge-accent",
        info: "badge-info",
        success: "badge-success",
        warning: "badge-warning",
        error: "badge-error"
    };

    const sizeClasses = {
        xs: "badge-xs",
        sm: "badge-sm",
        md: "",
        lg: "badge-lg"
    };
</script>

<span class="badge {variantClasses[variant]} {sizeClasses[size]} {userClass}">
    {@render children()}
</span> 