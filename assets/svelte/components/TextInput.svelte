<script>
    let {
        value = $bindable(""),
        placeholder = "",
        disabled = false,
        required = true,
        fullWidth = false,
        label = null,
        type = "text",
        size = "md", // xs, sm, md, lg
        variant = "bordered", // bordered, ghost
        oninput = null,
        class: userClass = "",
        ...restProps
    } = $props();

    const sizeClasses = {
        xs: "input-xs",
        sm: "input-sm",
        md: "input-md",
        lg: "input-lg",
    };

    const variantClasses = {
        bordered: "input-bordered",
        ghost: "input-ghost",
    };

    function handleInput(event) {
        value = event.target.value;
        if (oninput) {
            oninput(event);
        }
    }
</script>

<label class="input" for={type} class:w-full={fullWidth}>
    {#if label}
        <span class="label-text">{label}</span>
    {/if}

    <input
        {type}
        {value}
        {placeholder}
        {disabled}
        oninput={handleInput}
        class="{sizeClasses[size]} {variantClasses[variant]} {userClass}"
        {...restProps}
    />

    {#if !required}
        <span class="badge badge-neutral badge-xs">Optional</span>
    {/if}
</label>
