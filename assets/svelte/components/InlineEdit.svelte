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
        showEditButton = true, // Whether to show the edit button
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
        <div
            class="inline-edit-form bg-base-200/50 rounded-lg p-3 border border-base-300"
        >
            <div class="space-y-3">
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
                            <label
                                class="cursor-pointer label justify-start gap-3"
                            >
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

                <div class="flex items-center justify-end gap-2">
                    <Button
                        variant="ghost"
                        size="sm"
                        onclick={cancelEdit}
                        disabled={isSaving}
                        class="gap-2"
                        aria-label="Cancel changes"
                    >
                        <XIcon class="h-4 w-4" />
                        Cancel
                    </Button>

                    <Button
                        variant="primary"
                        size="sm"
                        onclick={saveEdit}
                        disabled={isSaving}
                        loading={isSaving}
                        class="gap-2"
                        aria-label="Save changes"
                    >
                        <CheckIcon class="h-4 w-4" />
                        {isSaving ? "Saving..." : "Save"}
                    </Button>
                </div>
            </div>
        </div>
    {:else}
        <div class="inline-edit-display group">
            <div class="flex items-start justify-between gap-3">
                <div class="flex-1 min-w-0">
                    {#if type === "boolean"}
                        <div class="flex items-center gap-2">
                            <div
                                class="badge badge-sm {value
                                    ? 'badge-secondary'
                                    : 'badge-primary'} font-medium"
                            >
                                {value ? "Private" : "Public"}
                            </div>
                        </div>
                    {:else if value}
                        <div class="text-base-content break-words">
                            {displayValue}
                        </div>
                    {:else}
                        <div class="text-base-content/50 italic">
                            {placeholder || "Click to add..."}
                        </div>
                    {/if}
                </div>

                {#if !disabled && showEditButton}
                    <Button
                        variant="ghost"
                        size="xs"
                        onclick={startEdit}
                        class="opacity-60 hover:opacity-100 transition-opacity gap-1"
                        aria-label="Edit"
                    >
                        <PencilIcon class="h-3 w-3" />
                        Edit
                    </Button>
                {/if}
            </div>
        </div>
    {/if}
</div>

<style>
    .inline-edit-container {
        width: 100%;
    }

    .inline-edit-display {
        min-height: 1.5rem;
    }

    .inline-edit-form {
        animation: slideIn 0.2s ease-out;
    }

    @keyframes slideIn {
        from {
            opacity: 0;
            transform: translateY(-4px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }
</style>
