<script>
    import { CheckIcon, XIcon, PencilIcon } from "lucide-svelte";
    import Button from "./Button.svelte";
    import TextInput from "./TextInput.svelte";
    import TextArea from "./TextArea.svelte";

    let {
        value = $bindable(""),
        type = "text", // 'text', 'textarea', 'boolean'
        placeholder = "",
        disabled = false,
        onSave,
        onCancel,
        displayFormatter = null, // Function to format display value
        class: userClass = "",
    } = $props();

    let isEditing = $state(false);
    let editValue = $state(value);
    let isSaving = $state(false);

    // Display value with optional formatting
    let displayValue = $derived(
        displayFormatter ? displayFormatter(value) : value,
    );

    function startEdit() {
        if (disabled) return;
        editValue = value;
        isEditing = true;
    }

    function cancelEdit() {
        editValue = value;
        isEditing = false;
        if (onCancel) onCancel();
    }

    async function saveEdit() {
        if (editValue === value) {
            isEditing = false;
            return;
        }

        isSaving = true;

        try {
            if (onSave) {
                await onSave(editValue);
            }
            value = editValue;
            isEditing = false;
        } catch (error) {
            console.error("Save failed:", error);
        } finally {
            isSaving = false;
        }
    }

    function handleKeydown(event) {
        if (event.key === "Escape") {
            cancelEdit();
        } else if (
            event.key === "Enter" &&
            !event.shiftKey &&
            type !== "textarea"
        ) {
            event.preventDefault();
            saveEdit();
        }
    }
</script>

<div class="inline-edit-container {userClass}">
    {#if isEditing}
        <div class="flex items-start gap-2">
            <div class="flex-1">
                {#if type === "text"}
                    <TextInput
                        bind:value={editValue}
                        {placeholder}
                        fullWidth={true}
                        size="sm"
                        onkeydown={handleKeydown}
                        autofocus
                    />
                {:else if type === "textarea"}
                    <TextArea
                        bind:value={editValue}
                        {placeholder}
                        size="sm"
                        rows={3}
                        onkeydown={handleKeydown}
                        class="w-full"
                        autofocus
                    />
                {:else if type === "boolean"}
                    <div class="form-control">
                        <label class="cursor-pointer label justify-start gap-3">
                            <input
                                type="checkbox"
                                bind:checked={editValue}
                                class="toggle toggle-primary toggle-sm"
                            />
                            <span class="label-text font-medium">
                                {editValue ? "Private Set" : "Public Set"}
                            </span>
                        </label>
                    </div>
                {/if}
            </div>

            <div class="flex items-center gap-1">
                <Button
                    variant="success"
                    size="xs"
                    onclick={saveEdit}
                    disabled={isSaving}
                    loading={isSaving}
                    class="btn-circle"
                    aria-label="Save changes"
                >
                    <CheckIcon class="h-3 w-3" />
                </Button>

                <Button
                    variant="ghost"
                    size="xs"
                    onclick={cancelEdit}
                    disabled={isSaving}
                    class="btn-circle"
                    aria-label="Cancel changes"
                >
                    <XIcon class="h-3 w-3" />
                </Button>
            </div>
        </div>
    {:else}
        <div
            class="inline-edit-display group cursor-pointer hover:bg-base-200/50 rounded-md px-2 py-1 -ml-2 transition-colors duration-200 {disabled
                ? 'cursor-not-allowed opacity-50'
                : ''}"
            onclick={startEdit}
            onkeydown={(e) => e.key === "Enter" && startEdit()}
            role="button"
            tabindex="0"
            aria-label="Click to edit"
        >
            <div class="flex items-center gap-2">
                <div class="flex-1 min-w-0">
                    {#if type === "boolean"}
                        <div class="flex items-center gap-2">
                            <div
                                class="badge badge-sm {value
                                    ? 'badge-secondary'
                                    : 'badge-primary'}"
                            >
                                {value ? "Private" : "Public"}
                            </div>
                        </div>
                    {:else if value}
                        <span class="text-base-content break-words">
                            {displayValue}
                        </span>
                    {:else}
                        <span class="text-base-content/50 italic">
                            {placeholder || "Click to add..."}
                        </span>
                    {/if}
                </div>

                {#if !disabled}
                    <PencilIcon
                        class="h-3 w-3 text-base-content/30 group-hover:text-base-content/60 transition-colors duration-200 shrink-0"
                    />
                {/if}
            </div>
        </div>
    {/if}
</div>

<style>
    .inline-edit-container {
        min-height: 1.5rem;
        width: 100%;
    }

    .inline-edit-display {
        min-height: 1.5rem;
        display: flex;
        align-items: center;
    }
</style>
