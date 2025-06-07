<script>
    import { SearchIcon, PlusIcon, CheckIcon, XIcon } from "lucide-svelte";
    import Modal from "../Modal.svelte";
    import Button from "../Button.svelte";
    import TextInput from "../TextInput.svelte";

    let {
        isOpen = false,
        onClose,
        questionSetId,
        currentTags = [],
        live,
    } = $props();

    let searchQuery = $state("");
    let availableTags = $state([]);
    let selectedTagIds = $state(new Set());
    let isCreatingTag = $state(false);
    let newTagName = $state("");
    let isInitialLoading = $state(false);
    let isSearching = $state(false);
    let hasInitializedTags = $state(false);
    let hasInitialized = $state(false);

    $effect(() => {
        if (isOpen) {
            if (!hasInitialized) {
                selectedTagIds = new Set(currentTags.map((tag) => tag.id));
                searchQuery = "";
                newTagName = "";
                isCreatingTag = false;
                hasInitializedTags = false;
                isInitialLoading = true;
                isSearching = false;
                hasInitialized = true;
                loadAvailableTags();
            }
        } else {
            hasInitialized = false;
        }
    });

    $effect(() => {
        if (hasInitialized && searchQuery !== undefined) {
            isSearching = true;
            loadAvailableTags();
        }
    });

    function loadAvailableTags() {
        if (live) {
            live.pushEvent("load_all_tags", { search_query: searchQuery });
        }
    }

    function toggleTagSelection(tagId) {
        if (selectedTagIds.has(tagId)) {
            selectedTagIds.delete(tagId);
        } else {
            selectedTagIds.add(tagId);
        }
        selectedTagIds = new Set(selectedTagIds); // Trigger reactivity
    }

    function handleCreateTag() {
        if (!newTagName.trim() || !live) return;

        live.pushEvent("create_tag", { name: newTagName.trim() });
        newTagName = "";
        isCreatingTag = false;
    }

    function handleSaveTags() {
        if (!live) return;

        const selectedTagsArray = Array.from(selectedTagIds).map(String);
        const currentTagIds = currentTags.map((tag) => tag.id);

        const tagsToAdd = selectedTagsArray.filter(
            (id) => !currentTagIds.includes(parseInt(id)),
        );
        const tagsToRemove = currentTagIds
            .filter((id) => !selectedTagIds.has(id))
            .map(String);

        if (tagsToAdd.length > 0) {
            live.pushEvent("add_tags_to_question_set", {
                question_set_id: String(questionSetId),
                tag_ids: tagsToAdd,
            });
        }

        if (tagsToRemove.length > 0) {
            live.pushEvent("remove_tags_from_question_set", {
                question_set_id: String(questionSetId),
                tag_ids: tagsToRemove,
            });
        }

        onClose();
    }

    function closeModal() {
        if (live) {
            live.pushEvent("clear_tags");
        }
        onClose();
    }

    $effect(() => {
        if (live) {
            const handleTagsLoaded = (data) => {
                availableTags = data.tags || [];
                if (!hasInitializedTags) {
                    hasInitializedTags = true;
                    isInitialLoading = false;
                } else {
                    isSearching = false;
                }
            };

            const handleTagCreated = (data) => {
                if (data.tag) {
                    availableTags = [...availableTags, data.tag];
                    selectedTagIds.add(data.tag.id);
                    selectedTagIds = new Set(selectedTagIds);
                }
            };

            const tagsLoadedHandle = live.handleEvent(
                "tags_loaded",
                handleTagsLoaded,
            );
            const tagCreatedHandle = live.handleEvent(
                "tag_created",
                handleTagCreated,
            );

            return () => {
                live.removeHandleEvent(tagsLoadedHandle);
                live.removeHandleEvent(tagCreatedHandle);
            };
        }
    });
</script>

<Modal {isOpen} onClose={closeModal} title="Manage Tags" size="md">
    <div class="space-y-4">
        <!-- Search and Quick Create -->
        <div class="flex flex-col sm:flex-row gap-3">
            <div class="flex-1 relative">
                <TextInput
                    bind:value={searchQuery}
                    placeholder="Search tags..."
                    fullWidth={true}
                    size="md"
                    variant="bordered"
                    icon={SearchIcon}
                    type="search"
                />
                {#if isSearching}
                    <div
                        class="absolute top-1/2 right-3 transform -translate-y-1/2"
                    >
                        <div
                            class="loading loading-spinner loading-xs text-primary"
                        ></div>
                    </div>
                {/if}
            </div>

            <Button
                variant="outline"
                size="md"
                onclick={() => (isCreatingTag = !isCreatingTag)}
                class="gap-2"
            >
                <PlusIcon class="h-4 w-4" />
                New Tag
            </Button>
        </div>

        <!-- Quick Create Form -->
        {#if isCreatingTag}
            <div class="bg-base-200 rounded-lg p-4 space-y-3">
                <h4 class="font-medium text-base-content">Create New Tag</h4>
                <div class="flex gap-2">
                    <TextInput
                        bind:value={newTagName}
                        placeholder="Enter tag name..."
                        fullWidth={true}
                        size="sm"
                        onkeydown={(e) =>
                            e.key === "Enter" && handleCreateTag()}
                    />
                    <Button
                        variant="primary"
                        size="sm"
                        onclick={handleCreateTag}
                        disabled={!newTagName.trim()}
                    >
                        Create
                    </Button>
                </div>
            </div>
        {/if}

        <!-- Tags List -->
        <div class="border border-base-300 rounded-lg max-h-80 overflow-y-auto">
            {#if isInitialLoading}
                <div class="p-8 text-center">
                    <div
                        class="loading loading-spinner loading-md text-primary"
                    ></div>
                    <p class="mt-2 text-base-content/60">Loading tags...</p>
                </div>
            {:else if availableTags.length === 0}
                <div class="p-8 text-center">
                    <div
                        class="w-16 h-16 mx-auto mb-3 bg-base-200 rounded-full flex items-center justify-center"
                    >
                        <SearchIcon class="h-8 w-8 text-base-content/30" />
                    </div>
                    <h3 class="font-medium text-base-content mb-1">
                        No tags found
                    </h3>
                    <p class="text-sm text-base-content/60">
                        {searchQuery
                            ? "Try a different search term or create a new tag"
                            : "Create your first tag"}
                    </p>
                </div>
            {:else}
                {#each availableTags as tag (tag.id)}
                    {@const isSelected = selectedTagIds.has(tag.id)}
                    <div
                        class="flex items-center gap-3 p-3 border-b border-base-300 last:border-b-0 hover:bg-base-50 transition-colors cursor-pointer"
                        onclick={() => toggleTagSelection(tag.id)}
                        onkeydown={(e) =>
                            e.key === "Enter" && toggleTagSelection(tag.id)}
                        role="button"
                        tabindex="0"
                    >
                        <input
                            type="checkbox"
                            checked={isSelected}
                            onchange={() => toggleTagSelection(tag.id)}
                            class="checkbox checkbox-primary checkbox-sm"
                        />

                        <div class="flex-1 min-w-0">
                            <span class="badge badge-outline">{tag.name}</span>
                        </div>

                        {#if isSelected}
                            <CheckIcon class="h-4 w-4 text-success" />
                        {/if}
                    </div>
                {/each}
            {/if}
        </div>

        <!-- Selected Count and Actions -->
        <div
            class="flex items-center justify-between pt-4 border-t border-base-300"
        >
            <span class="text-sm text-base-content/60">
                {selectedTagIds.size} tag(s) selected
            </span>

            <div class="flex gap-2">
                <Button variant="ghost" onclick={closeModal}>Cancel</Button>
                <Button
                    variant="primary"
                    onclick={handleSaveTags}
                    class="gap-2"
                >
                    <CheckIcon class="h-4 w-4" />
                    Save Tags
                </Button>
            </div>
        </div>
    </div>
</Modal>
