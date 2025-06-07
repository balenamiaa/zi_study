<script>
    import { SearchIcon, PlusIcon, CheckIcon } from "lucide-svelte";
    import Modal from "../Modal.svelte";
    import Button from "../Button.svelte";
    import TextInput from "../TextInput.svelte";

    let {
        isOpen = false,
        onClose,
        questionIds = [],
        userQuestionSets,
        live,
        currentUser,
    } = $props();

    let searchQuery = $state("");
    let selectedSetIds = $state(new Set());
    let isCreatingSet = $state(false);
    let newSetTitle = $state("");
    let currentPage = $state(1);
    let isLoading = $state(false);
    let error = $state(null);
    let questionSets = $state([]);
    let totalPages = $state(1);

    $effect(() => {
        if (isOpen && live) {
            selectedSetIds.clear();
            searchQuery = "";
            newSetTitle = "";
            currentPage = 1;
            loadQuestionSets();
        }
    });

    function loadQuestionSets() {
        if (!live) return;
        
        isLoading = true;
        error = null;
        
        // For bulk operations, we'll fetch all accessible question sets
        live.pushEvent("load_accessible_question_sets", {
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
        selectedSetIds = new Set(selectedSetIds);
    }

    function handleQuickCreate() {
        if (!newSetTitle.trim() || !live) return;

        isCreatingSet = true;
        live.pushEvent("quick_create_question_set", {
            title: newSetTitle.trim(),
        });
    }

    function handleBulkAddToSets() {
        if (!live || selectedSetIds.size === 0) return;

        const selectedSetIdArray = Array.from(selectedSetIds).map(String);
        
        live.pushEvent("bulk_add_questions_to_sets", {
            question_ids: questionIds.map(String),
            question_set_ids: selectedSetIdArray
        });

        onClose();
    }

    function closeModal() {
        onClose();
        
        if (live) {
            live.pushEvent("clear_accessible_question_sets");
        }
    }

    // Handle events
    $effect(() => {
        if (!live) return;

        const setsLoadedHandle = live.handleEvent("accessible_sets_loaded", (data) => {
            questionSets = data.items || [];
            totalPages = data.total_pages || 1;
            isLoading = false;
        });

        const setCreatedHandle = live.handleEvent("set_created", () => {
            isCreatingSet = false;
            newSetTitle = "";
            loadQuestionSets();
        });

        const questionsAddedHandle = live.handleEvent("questions_added_to_sets", ({ count }) => {
            onClose();
        });

        return () => {
            live.removeHandleEvent(setsLoadedHandle);
            live.removeHandleEvent(setCreatedHandle);
            live.removeHandleEvent(questionsAddedHandle);
        };
    });
</script>

<Modal {isOpen} onClose={closeModal} title="Add {questionIds.length} Questions to Sets" size="lg">
    <div class="space-y-4">
        <!-- Search and Quick Create -->
        <div class="flex flex-col sm:flex-row gap-3">
            <div class="flex-1 relative">
                <label class="input relative flex items-center gap-2">
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
                <h4 class="font-medium text-base-content">
                    Create New Question Set
                </h4>
                <div class="flex gap-2">
                    <TextInput
                        bind:value={newSetTitle}
                        placeholder="Enter set title..."
                        fullWidth={true}
                        size="sm"
                        onkeydown={(e) =>
                            e.key === "Enter" && handleQuickCreate()}
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
            </div>
        {/if}

        <!-- Question Sets List -->
        <div class="border border-base-300 rounded-lg">
            {#if isLoading}
                <div class="p-8 text-center">
                    <div class="loading loading-spinner loading-md text-primary"></div>
                    <p class="mt-2 text-base-content/60">
                        Loading question sets...
                    </p>
                </div>
            {:else if questionSets.length === 0}
                <div class="p-8 text-center">
                    <div class="w-16 h-16 mx-auto mb-3 bg-base-200 rounded-full flex items-center justify-center">
                        <SearchIcon class="h-8 w-8 text-base-content/30" />
                    </div>
                    <h3 class="font-medium text-base-content mb-1">
                        No sets found
                    </h3>
                    <p class="text-sm text-base-content/60">
                        {searchQuery
                            ? "Try a different search term"
                            : "Create your first question set"}
                    </p>
                </div>
            {:else}
                <div class="max-h-96 overflow-y-auto">
                    {#each questionSets as questionSet (questionSet.id)}
                        {@const isSelected = selectedSetIds.has(questionSet.id)}
                        {@const canModify = questionSet.owner?.email === currentUser?.email}
                        
                        <div
                            class="flex items-center gap-3 p-3 border-b border-base-300 last:border-b-0 hover:bg-base-50 transition-colors {canModify
                                ? 'cursor-pointer'
                                : 'opacity-60'}"
                            onclick={() => canModify && toggleSetSelection(questionSet.id)}
                            onkeydown={(e) =>
                                e.key === "Enter" &&
                                canModify &&
                                toggleSetSelection(questionSet.id)}
                            role="button"
                            tabindex="0"
                        >
                            <input
                                type="checkbox"
                                checked={isSelected}
                                disabled={!canModify}
                                class="checkbox checkbox-primary checkbox-sm pointer-events-none"
                            />

                            <div class="flex-1 min-w-0">
                                <div class="flex items-center gap-2 mb-1">
                                    <h4 class="font-medium text-base-content truncate">
                                        {questionSet.title}
                                    </h4>
                                    <div class="flex gap-1">
                                        <div class="badge badge-xs {questionSet.is_private
                                            ? 'badge-secondary'
                                            : 'badge-primary'}">
                                            {questionSet.is_private ? "Private" : "Public"}
                                        </div>
                                        {#if !canModify}
                                            <div class="badge badge-xs badge-outline">
                                                Read-only
                                            </div>
                                        {/if}
                                    </div>
                                </div>
                                {#if questionSet.description}
                                    <p class="text-sm text-base-content/60 truncate">
                                        {questionSet.description}
                                    </p>
                                {/if}
                                <p class="text-xs text-base-content/40 mt-1">
                                    {questionSet.num_questions || 0} questions
                                    {#if questionSet.owner && !canModify}
                                        • by {questionSet.owner.email}
                                    {/if}
                                </p>
                            </div>
                        </div>
                    {/each}
                </div>

                <!-- Pagination -->
                {#if totalPages > 1}
                    <div class="p-4 border-t border-base-300">
                        <div class="flex items-center justify-between">
                            <span class="text-sm text-base-content/60">
                                Page {currentPage} of {totalPages}
                            </span>
                            <div class="join">
                                <Button
                                    variant="outline"
                                    size="xs"
                                    disabled={currentPage <= 1}
                                    onclick={() => handlePageChange(currentPage - 1)}
                                    class="join-item"
                                >
                                    Prev
                                </Button>
                                <Button
                                    variant="outline"
                                    size="xs"
                                    disabled={currentPage >= totalPages}
                                    onclick={() => handlePageChange(currentPage + 1)}
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

        <!-- Actions -->
        <div class="flex items-center justify-between pt-4 border-t border-base-300">
            <div class="text-sm text-base-content/60">
                {#if selectedSetIds.size > 0}
                    <span class="text-primary font-medium">
                        {selectedSetIds.size} set(s) selected
                    </span>
                {:else}
                    <span>Select sets to add questions to</span>
                {/if}
            </div>

            <div class="flex gap-2">
                <Button variant="ghost" onclick={closeModal}>Cancel</Button>
                <Button
                    variant="primary"
                    onclick={handleBulkAddToSets}
                    disabled={selectedSetIds.size === 0}
                    class="gap-2"
                >
                    <CheckIcon class="h-4 w-4" />
                    Add to {selectedSetIds.size} Set{selectedSetIds.size === 1 ? '' : 's'}
                </Button>
            </div>
        </div>
    </div>
</Modal> 