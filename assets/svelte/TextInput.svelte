<script>
    export let type = "text";
    export let label = "";
    export let placeholder = "";
    export let value = "";
    export let onInput = null;
    export let helperText = "";
    export let disabled = false;
    export let required = false;
    export let error = false;

    function handleInput(event) {
        if (onInput) {
            onInput(event);
        }
    }
</script>

<div class="form-control w-full">
    {#if label}
        <label class="label">
            <span class="label-text">{label}</span>
            {#if required}
                <span class="label-text-alt text-error">*</span>
            {/if}
        </label>
    {/if}
    
    <input 
        {type}
        {placeholder}
        {value}
        {disabled}
        {required}
        class="input input-bordered w-full {error ? 'input-error' : ''}"
        on:input={handleInput}
    />
    
    {#if helperText}
        <label class="label">
            <span class="label-text-alt {error ? 'text-error' : 'text-base-content/70'}">{helperText}</span>
        </label>
    {/if}
</div> 