<script>
    import { twMerge } from "tailwind-merge";

    let {
        value = $bindable(""),
        placeholder = "",
        disabled = false,
        rows = 4,
        size = "md", // xs, sm, md, lg
        variant = "bordered", // bordered, ghost
        enabledResize = false,
        oninput = null,
        class: userClass = "",
        ...restProps
    } = $props();

    const sizeClasses = {
        xs: "textarea-xs",
        sm: "textarea-sm",
        md: "textarea-md",
        lg: "textarea-lg",
    };

    const variantClasses = {
        bordered: "textarea-bordered",
        ghost: "textarea-ghost",
    };

    function handleInput(event) {
        value = event.target.value;
        if (oninput) {
            oninput(event);
        }
    }
</script>

<textarea
    {value}
    {placeholder}
    {disabled}
    {rows}
    oninput={handleInput}
    class={twMerge(
        "textarea",
        sizeClasses[size],
        variantClasses[variant],
        userClass,
    )}
    class:resize-none={!enabledResize}
    {...restProps}
></textarea>
