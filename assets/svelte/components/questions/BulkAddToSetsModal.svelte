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
    let isSubmitting = $state(false);
    let error = $state(null);
    let questionSets = $state([]);
    let totalPages = $state(1);
    let hasInitialized = $state(false);
    let isInitialLoading = $state(false);
    let isSearching = $state(false);

    $effect(() => {
        if (isOpen && live) {
            if (!hasInitialized) {
                selectedSetIds = new Set();
                searchQuery = "";
                newSetTitle = "";
                currentPage = 1;
                isSubmitting = false;
                error = null;
                hasInitialized = true;
                isInitialLoading = true;
                loadQuestionSets();
            }
        } else {
            hasInitialized = false;
        }
    });

    // Auto-search when query changes
    $effect(() => {
        if (hasInitialized && searchQuery !== undefined) {
            currentPage = 1;
            isSearching = true;
            loadQuestionSets();
        }
    });

    function loadQuestionSets() {
        if (!live) return;

        error = null;

        live.pushEvent("load_accessible_question_sets", {
            page_number: currentPage,
            search_query: searchQuery,
        });
    }

    function handlePageChange(page) {
        currentPage = page;
        loadQuestionSets();
    }

    function toggleSetSelection(setId) {
        // Create a new Set to ensure reactivity
        const newSelectedSetIds = new Set(selectedSetIds);

        if (newSelectedSetIds.has(setId)) {
            newSelectedSetIds.delete(setId);
        } else {
            newSelectedSetIds.add(setId);
        }

        selectedSetIds = newSelectedSetIds;
    }

    function handleQuickCreate() {
        if (!newSetTitle.trim() || !live) return;

        isCreatingSet = true;
        live.pushEvent("quick_create_question_set", {
            title: newSetTitle.trim(),
        });
    }

    function handleBulkAddToSets() {
        if (!live || selectedSetIds.size === 0 || isSubmitting) return;

        const selectedSetIdArray = Array.from(selectedSetIds).map(String);

        isSubmitting = true;
        error = null;

        live.pushEvent("bulk_add_questions_to_sets", {
            question_ids: questionIds.map(String),
            question_set_ids: selectedSetIdArray,
        });

        // Don't close immediately - wait for success response
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

        const setsLoadedHandle = live.handleEvent(
            "accessible_sets_loaded",
            (data) => {
                questionSets = data.items || [];
                totalPages = data.total_pages || 1;
                isInitialLoading = false;
                isSearching = false;
            },
        );

        const setCreatedHandle = live.handleEvent("set_created", () => {
            isCreatingSet = false;
            newSetTitle = "";
            // Reload to include the new set
            loadQuestionSets();
        });

        const questionsAddedHandle = live.handleEvent(
            "questions_added_to_sets",
            ({ count }) => {
                isSubmitting = false;
                onClose();
            },
        );

        const errorHandle = live.handleEvent("error", (errorData) => {
            isSubmitting = false;
            error = errorData.message || "An error occurred";
        });

        return () => {
            live.removeHandleEvent(setsLoadedHandle);
            live.removeHandleEvent(setCreatedHandle);
            live.removeHandleEvent(questionsAddedHandle);
            live.removeHandleEvent(errorHandle);
        };
    });
</script>

<Modal
    {isOpen}
    onClose={closeModal}
    title="Add {questionIds.length} Questions to Sets"
    size="lg"
>
    <div class="space-y-4">
        <!-- Search and Quick Create -->
        <div class="flex flex-col sm:flex-row gap-3">
            <div class="flex-1">
                <TextInput
                    bind:value={searchQuery}
                    placeholder="Search question sets..."
                    fullWidth={true}
                    size="md"
                    variant="bordered"
                    icon={SearchIcon}
                />
            </div>

            <Button
                variant="outline"
                size="md"
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
            {#if isInitialLoading}
                <div class="p-8 text-center">
                    <div
                        class="loading loading-spinner loading-md text-primary"
                    ></div>
                    <p class="mt-2 text-base-content/60">
                        Loading question sets...
                    </p>
                </div>
            {:else if questionSets.length === 0}
                <div class="p-8 text-center">
                    <div
                        class="w-16 h-16 mx-auto mb-3 bg-base-200 rounded-full flex items-center justify-center"
                    >
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
                <div class="max-h-96 overflow-y-auto relative">
                    {#if isSearching}
                        <div class="absolute top-2 right-2 z-10">
                            <div
                                class="loading loading-spinner loading-sm text-primary"
                            ></div>
                        </div>
                    {/if}
                    {#each questionSets as questionSet (questionSet.id)}
                        {@const isSelected = selectedSetIds.has(questionSet.id)}
                        {@const canModify =
                            questionSet.owner?.email === currentUser?.email}

                        <div
                            class="flex items-center gap-3 p-3 border-b border-base-300 last:border-b-0 hover:bg-base-50 transition-colors {canModify
                                ? 'cursor-pointer'
                                : 'opacity-60'}"
                            onclick={() =>
                                canModify && toggleSetSelection(questionSet.id)}
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
                                    <h4
                                        class="font-medium text-base-content truncate"
                                    >
                                        {questionSet.title}
                                    </h4>
                                    <div class="flex gap-1">
                                        <div
                                            class="badge badge-xs {questionSet.is_private
                                                ? 'badge-secondary'
                                                : 'badge-primary'}"
                                        >
                                            {questionSet.is_private
                                                ? "Private"
                                                : "Public"}
                                        </div>
                                        {#if !canModify}
                                            <div
                                                class="badge badge-xs badge-outline shrink-0"
                                            >
                                                Read-only
                                            </div>
                                        {/if}
                                    </div>
                                </div>
                                {#if questionSet.description}
                                    <p
                                        class="text-sm text-base-content/60 truncate"
                                    >
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
                                    onclick={() =>
                                        handlePageChange(currentPage - 1)}
                                    class="join-item"
                                >
                                    Prev
                                </Button>
                                <Button
                                    variant="outline"
                                    size="xs"
                                    disabled={currentPage >= totalPages}
                                    onclick={() =>
                                        handlePageChange(currentPage + 1)}
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

        <!-- Error Display -->
        {#if error}
            <div
                class="bg-error/10 border border-error/30 rounded-lg p-3 text-error text-sm"
            >
                {error}
            </div>
        {/if}

        <!-- Actions -->
        <div
            class="flex items-center justify-between pt-4 border-t border-base-300"
        >
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
                <Button
                    variant="ghost"
                    onclick={closeModal}
                    disabled={isSubmitting}>Cancel</Button
                >
                <Button
                    variant="primary"
                    onclick={handleBulkAddToSets}
                    disabled={selectedSetIds.size === 0 || isSubmitting}
                    class="gap-2"
                >
                    {#if isSubmitting}
                        <div class="loading loading-spinner loading-xs"></div>
                        Adding...
                    {:else}
                        <CheckIcon class="h-4 w-4" />
                        Add to {selectedSetIds.size} Set{selectedSetIds.size ===
                        1
                            ? ""
                            : "s"}
                    {/if}
                </Button>
            </div>
        </div>
    </div>
</Modal>
