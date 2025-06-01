<script>
    let {
        value = $bindable(),
        type,
        label,
        fullWidth = false,
        placeholder,
        disabled,
        required,
        error,
        ...restProps
    } = $props();
</script>

<div {...restProps}>
    <label class="input" for={type} class:w-full={fullWidth}>
        {#if label}
            <span class="label-text">{label}</span>
        {/if}

        <input
            {type}
            {placeholder}
            bind:value
            {disabled}
            {required}
            class="grow"
            class:input-error={error}
        />

        {#if !required}
            <span class="badge badge-neutral badge-xs">Optional</span>
        {/if}
    </label>
</div>
