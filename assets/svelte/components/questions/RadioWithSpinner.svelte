<script>
    let {
        checked = false,
        disabled = false,
        showSpinner = false,
        onchange,
        name,
        value,
        class: userClass = "",
        variant = "primary",
        ...restProps
    } = $props();

    function handleChange(event) {
        if (onchange && !disabled) {
            onchange(event);
        }
    }

    const radioClass = $derived(() => {
        const classes = {
            primary: "radio-primary",
            success: "radio-success",
            error: "radio-error",
        };
        return classes[variant] || "radio-primary";
    });

    const spinnerColor = $derived(() => {
        const colors = {
            primary: "text-primary",
            success: "text-success",
            error: "text-error",
        };
        return colors[variant] || "text-primary";
    });
</script>

<div class="relative inline-flex items-center">
    <input
        type="radio"
        {name}
        {value}
        {checked}
        {disabled}
        onchange={handleChange}
        class="radio {radioClass()} mt-1 {userClass}"
        {...restProps}
    />

    {#if showSpinner}
        <div class="absolute inset-0 flex items-center justify-center mt-1">
            <div
                class="loading loading-spinner loading-xs {spinnerColor()} opacity-80"
            ></div>
        </div>
    {/if}
</div>
