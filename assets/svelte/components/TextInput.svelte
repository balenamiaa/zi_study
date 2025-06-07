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
        icon = null, // Icon component to display
        oninput = null,
        onkeydown = null,
        class: userClass = "",
        ...restProps
    } = $props();

    let inputElement = $state(null);

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

    function handleKeydown(event) {
        if (onkeydown) {
            onkeydown(event);
        }
    }

    // Expose focus method for parent components
    export function focus() {
        if (inputElement) {
            inputElement.focus();
        }
    }
</script>

<label
    class="input {sizeClasses[size]} {variantClasses[
        variant
    ]} flex items-center gap-2 {userClass}"
    class:w-full={fullWidth}
>
    {#if label}
        <span>{label}</span>
    {/if}
    {#if icon}
        {@const Icon = icon}
        <Icon class="h-4 w-4 text-base-content/50" />
    {/if}

    <input
        bind:this={inputElement}
        {type}
        bind:value
        {placeholder}
        {disabled}
        oninput={handleInput}
        onkeydown={handleKeydown}
        class="grow"
        {...restProps}
    />

    {#if !required}
        <span class="badge badge-neutral badge-xs">Optional</span>
    {/if}
</label>
