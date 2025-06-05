<script>
    import { SearchIcon, PlusIcon, CheckIcon } from "lucide-svelte";
    import Modal from "../Modal.svelte";
    import Button from "../Button.svelte";
    import TextInput from "../TextInput.svelte";

    let {
        isOpen = false,
        onClose,
        questionId,
        live,
        userQuestionSets = null,
    } = $props();

    let searchQuery = $state("");
    let selectedSetIds = $state(new Set());
    let isCreatingSet = $state(false);
    let newSetTitle = $state("");
    let currentPage = $state(1);

    // Reset state when modal opens/closes
    $effect(() => {
        if (isOpen) {
            selectedSetIds.clear();
            searchQuery = "";
            newSetTitle = "";
            currentPage = 1;
            loadQuestionSets();
        }
    });

    function loadQuestionSets() {
        live.pushEvent("load_user_question_sets", {
            page_number: currentPage,
            search_query: searchQuery,
        });
    }

    function handleSearch() {
        currentPage = 1;
        loadQuestionSets();
    }

    function handlePageChange(page) {
        currentPage = page;
        loadQuestionSets();
    }

    function toggleSetSelection(setId) {
        if (selectedSetIds.has(setId)) {
            selectedSetIds.delete(setId);
        } else {
            selectedSetIds.add(setId);
        }
        selectedSetIds = new Set(selectedSetIds); // Trigger reactivity
    }

    function handleQuickCreate() {
        if (!newSetTitle.trim()) return;

        isCreatingSet = true;
        live.pushEvent("quick_create_question_set", { title: newSetTitle.trim() });
    }

    function handleAddToSets() {
        if (selectedSetIds.size === 0) return;

        const questionSetIds = Array.from(selectedSetIds).map(String);
        live.pushEvent("add_question_to_sets", {
            question_id: String(questionId),
            question_set_ids: questionSetIds,
        });

        onClose();
    }

    function closeModal() {
        live.pushEvent("clear_user_question_sets");
        onClose();
    }

    // Listen for set creation success
    $effect(() => {
        if (isCreatingSet && userQuestionSets) {
            isCreatingSet = false;
            newSetTitle = "";
            // Automatically refresh the list
            loadQuestionSets();
        }
    });
</script>

<Modal {isOpen} onClose={closeModal} title="Add to Question Sets" size="lg">
    <div class="space-y-4">
        <!-- Search and Quick Create -->
        <div class="flex flex-col sm:flex-row gap-3">
            <div class="flex-1 relative">
                <label for="search" class="input relative flex items-center gap-2">
                    <SearchIcon class="h-4 w-4 text-base-content/50" />
                    <input
                        type="search"
                        bind:value={searchQuery}
                        oninput={handleSearch}
                        placeholder="Search question sets..."
                        class="grow"
                    />
                </label>
            </div>

            <Button
                variant="outline"
                size="sm"
                onclick={() => (isCreatingSet = !isCreatingSet)}
                class="gap-2"
            >
                <PlusIcon class="h-4 w-4" />
                Quick Create
            </Button>
        </div>

        <!-- Quick Create Form -->
        {#if isCreatingSet}
            <div class="bg-base-200 rounded-lg p-4 space-y-3">
                <h4 class="font-medium text-base-content">Create New Question Set</h4>
                <div class="flex gap-2">
                    <TextInput
                        bind:value={newSetTitle}
                        placeholder="Enter set title..."
                        fullWidth={true}
                        size="sm"
                        onkeydown={(e) => e.key === "Enter" && handleQuickCreate()}
                    />
                    <Button
                        variant="primary"
                        size="sm"
                        onclick={handleQuickCreate}
                        disabled={!newSetTitle.trim()}
                    >
                        Create
                    </Button>
                </div>
                <p class="text-xs text-base-content/60">
                    Creates a private set that you can immediately add questions to.
                </p>
            </div>
        {/if}

        <!-- Question Sets List -->
        <div class="border border-base-300 rounded-lg">
            {#if !userQuestionSets}
                <div class="p-8 text-center">
                    <div class="loading loading-spinner loading-md text-primary"></div>
                    <p class="mt-2 text-base-content/60">Loading question sets...</p>
                </div>
            {:else if userQuestionSets.items.length === 0}
                <div class="p-8 text-center">
                    <div class="w-16 h-16 mx-auto mb-3 bg-base-200 rounded-full flex items-center justify-center">
                        <SearchIcon class="h-8 w-8 text-base-content/30" />
                    </div>
                    <h3 class="font-medium text-base-content mb-1">No sets found</h3>
                    <p class="text-sm text-base-content/60">
                        {searchQuery ? "Try a different search term" : "Create your first question set"}
                    </p>
                </div>
            {:else}
                <div class="max-h-96 overflow-y-auto">
                    {#each userQuestionSets.items as questionSet (questionSet.id)}
                        {@const isSelected = selectedSetIds.has(questionSet.id)}
                        {@const canSelect = questionSet.is_owned}
                        <div
                            class="flex items-center gap-3 p-3 border-b border-base-300 last:border-b-0 hover:bg-base-50 transition-colors {canSelect
                                ? 'cursor-pointer'
                                : 'opacity-60'}"
                            onclick={() => canSelect && toggleSetSelection(questionSet.id)}
                        >
                            <input
                                type="checkbox"
                                checked={isSelected}
                                disabled={!canSelect}
                                onchange={() => canSelect && toggleSetSelection(questionSet.id)}
                                class="checkbox checkbox-primary checkbox-sm"
                            />

                            <div class="flex-1 min-w-0">
                                <div class="flex items-center gap-2 mb-1">
                                    <h4 class="font-medium text-base-content truncate">
                                        {questionSet.title}
                                    </h4>
                                    <div class="flex gap-1">
                                        <div class="badge badge-xs {questionSet.is_private ? 'badge-secondary' : 'badge-primary'}">
                                            {questionSet.is_private ? "Private" : "Public"}
                                        </div>
                                        {#if !questionSet.is_owned}
                                            <div class="badge badge-xs badge-outline">Read-only</div>
                                        {/if}
                                    </div>
                                </div>
                                {#if questionSet.description}
                                    <p class="text-sm text-base-content/60 truncate">
                                        {questionSet.description}
                                    </p>
                                {/if}
                                {#if questionSet.owner && !questionSet.is_owned}
                                    <p class="text-xs text-base-content/40 mt-1">
                                        by {questionSet.owner.email}
                                    </p>
                                {/if}
                            </div>

                            {#if isSelected}
                                <CheckIcon class="h-4 w-4 text-success" />
                            {/if}
                        </div>
                    {/each}
                </div>

                <!-- Pagination -->
                {#if userQuestionSets.total_pages > 1}
                    <div class="p-4 border-t border-base-300">
                        <div class="flex items-center justify-between">
                            <span class="text-sm text-base-content/60">
                                Page {userQuestionSets.page_number} of {userQuestionSets.total_pages}
                                ({userQuestionSets.total_items} total)
                            </span>
                            <div class="join">
                                <Button
                                    variant="outline"
                                    size="xs"
                                    disabled={userQuestionSets.page_number <= 1}
                                    onclick={() => handlePageChange(userQuestionSets.page_number - 1)}
                                    class="join-item"
                                >
                                    Prev
                                </Button>
                                <Button
                                    variant="outline"
                                    size="xs"
                                    disabled={userQuestionSets.page_number >= userQuestionSets.total_pages}
                                    onclick={() => handlePageChange(userQuestionSets.page_number + 1)}
                                    class="join-item"
                                >
                                    Next
                                </Button>
                            </div>
                        </div>
                    </div>
                {/if}
            {/if}
        </div>

        <!-- Selected Count and Actions -->
        <div class="flex items-center justify-between pt-4 border-t border-base-300">
            <span class="text-sm text-base-content/60">
                {selectedSetIds.size} set(s) selected
            </span>

            <div class="flex gap-2">
                <Button variant="ghost" onclick={closeModal}>
                    Cancel
                </Button>
                <Button
                    variant="primary"
                    onclick={handleAddToSets}
                    disabled={selectedSetIds.size === 0}
                    class="gap-2"
                >
                    <PlusIcon class="h-4 w-4" />
                    Add to {selectedSetIds.size} Set(s)
                </Button>
            </div>
        </div>
    </div>
</Modal> 