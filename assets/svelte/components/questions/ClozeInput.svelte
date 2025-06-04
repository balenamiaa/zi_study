<script>
    let {
        value = $bindable(""),
        placeholder = "",
        disabled = false,
        class: userClass = "",
        ...restProps
    } = $props();
</script>

<input
    type="text"
    bind:value
    {placeholder}
    {disabled}
    class="cloze-input bg-transparent border-0 border-b-2 border-primary/30 focus:border-primary focus:outline-none text-center px-1 py-0.5 text-sm font-medium min-w-0 transition-all duration-200 {userClass}"
    {...restProps}
/>

<style>
    .cloze-input:focus {
        background-color: hsl(var(--p) / 0.05);
        transform: scale(1.02);
    }

    .cloze-input::placeholder {
        font-size: 0.75rem;
    }
</style>
