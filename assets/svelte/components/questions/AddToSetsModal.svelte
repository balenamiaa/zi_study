<script>
    import { SearchIcon, PlusIcon, EditIcon } from "lucide-svelte";
    import Modal from "../Modal.svelte";
    import Button from "../Button.svelte";
    import TextInput from "../TextInput.svelte";

    let {
        isOpen = false,
        onClose,
        questionId,
        userQuestionSets,
        live,
    } = $props();

    let searchQuery = $state("");
    let selectedSetIds = $state([]);
    let initialSetIds = $state([]);
    let isCreatingSet = $state(false);
    let newSetTitle = $state("");
    let currentPage = $state(1);
    let hasInitializedSelections = $state(false);
    let isLoading = $state(false);
    let error = $state(null);

    $effect(() => {
        if (isOpen && live) {
            selectedSetIds = [];
            initialSetIds = [];
            hasInitializedSelections = false;
            searchQuery = "";
            newSetTitle = "";
            currentPage = 1;

            loadQuestionSets();
        }
    });

    function loadQuestionSets() {
        if (live) {
            isLoading = true;
            error = null;
            live.pushEvent("load_owned_question_sets_for_question", {
                question_id: String(questionId),
                page_number: currentPage,
                search_query: searchQuery,
            });
        }
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
        if (selectedSetIds.includes(setId)) {
            selectedSetIds = selectedSetIds.filter((id) => id !== setId);
        } else {
            selectedSetIds = [...selectedSetIds, setId];
        }
    }

    function handleQuickCreate() {
        if (!newSetTitle.trim() || !live) return;

        isCreatingSet = true;
        live.pushEvent("quick_create_question_set", {
            title: newSetTitle.trim(),
        });
    }

    function handleModifySets() {
        if (!live || !userQuestionSets) return;

        const modifications = userQuestionSets.items.map((questionSet) => ({
            set_id: String(questionSet.id),
            should_contain: selectedSetIds.includes(questionSet.id),
        }));

        live.pushEvent("modify_question_sets", {
            question_id: String(questionId),
            question_set_modifications: modifications,
        });

        onClose();
    }

    function closeModal() {
        onClose();

        if (live) {
            live.pushEvent("clear_user_question_sets");
        }
    }

    $effect(() => {
        if (userQuestionSets?.items && !hasInitializedSelections) {
            const containingIds = userQuestionSets.items
                .filter((item) => item.contains_question)
                .map((item) => item.id);

            initialSetIds = [...containingIds];
            selectedSetIds = [...containingIds];
            hasInitializedSelections = true;
            isLoading = false;
        }
    });

    $effect(() => {
        if (!live) return;

        const handleSetCreated = () => {
            isCreatingSet = false;
            newSetTitle = "";
            loadQuestionSets();
        };

        const handleModifySuccess = () => {
            if (live) {
                live.pushEvent("clear_user_question_sets");
            }
            onClose();
        };

        const setCreatedHandle = live.handleEvent(
            "set_created",
            handleSetCreated,
        );
        const questionSetsModifiedHandle = live.handleEvent(
            "question_sets_modified",
            handleModifySuccess,
        );

        return () => {
            live.removeHandleEvent(setCreatedHandle);
            live.removeHandleEvent(questionSetsModifiedHandle);
        };
    });

    function getChangesInfo() {
        const toAdd = selectedSetIds.filter(
            (id) => !initialSetIds.includes(id),
        );
        const toRemove = initialSetIds.filter(
            (id) => !selectedSetIds.includes(id),
        );
        return { toAdd, toRemove };
    }
</script>

<Modal {isOpen} onClose={closeModal} title="Modify Question Sets" size="lg">
    <div class="space-y-4">
        <!-- Search and Quick Create -->
        <div class="flex flex-col sm:flex-row gap-3">
            <div class="flex-1 relative">
                <label
                    for="search"
                    class="input relative flex items-center gap-2"
                >
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
                <p class="text-xs text-base-content/60">
                    Creates a private set that you can immediately add questions
                    to.
                </p>
            </div>
        {/if}

        <!-- Question Sets List -->
        <div class="border border-base-300 rounded-lg">
            {#if isLoading || !userQuestionSets}
                <div class="p-8 text-center">
                    <div
                        class="loading loading-spinner loading-md text-primary"
                    ></div>
                    <p class="mt-2 text-base-content/60">
                        Loading question sets...
                    </p>
                </div>
            {:else if userQuestionSets.items.length === 0}
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
                <div class="max-h-96 overflow-y-auto">
                    {#each userQuestionSets.items as questionSet (questionSet.id)}
                        {@const isSelected = selectedSetIds.includes(
                            questionSet.id,
                        )}
                        {@const wasInitiallySelected =
                            questionSet.contains_question}
                        {@const canSelect = questionSet.is_owned}
                        {@const isChanged = isSelected !== wasInitiallySelected}
                        <div
                            class="flex items-center gap-3 p-3 border-b border-base-300 last:border-b-0 hover:bg-base-50 transition-colors {canSelect
                                ? 'cursor-pointer'
                                : 'opacity-60'}"
                            onclick={() =>
                                canSelect && toggleSetSelection(questionSet.id)}
                            onkeydown={(e) =>
                                e.key === "Enter" &&
                                canSelect &&
                                toggleSetSelection(questionSet.id)}
                            role="button"
                            tabindex="0"
                        >
                            <input
                                type="checkbox"
                                checked={isSelected}
                                disabled={!canSelect}
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
                                        {#if !questionSet.is_owned}
                                            <div
                                                class="badge badge-xs badge-outline"
                                            >
                                                Read-only
                                            </div>
                                        {/if}
                                        {#if wasInitiallySelected}
                                            <div
                                                class="badge badge-xs badge-info"
                                            >
                                                Contains Question
                                            </div>
                                        {/if}
                                        {#if isChanged && canSelect}
                                            <div
                                                class="badge badge-xs {isSelected
                                                    ? 'badge-success'
                                                    : 'badge-warning'}"
                                            >
                                                {isSelected
                                                    ? "Will Add"
                                                    : "Will Remove"}
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
                                {#if questionSet.owner && !questionSet.is_owned}
                                    <p
                                        class="text-xs text-base-content/40 mt-1"
                                    >
                                        by {questionSet.owner.email}
                                    </p>
                                {/if}
                            </div>
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
                                    onclick={() =>
                                        handlePageChange(
                                            userQuestionSets.page_number - 1,
                                        )}
                                    class="join-item"
                                >
                                    Prev
                                </Button>
                                <Button
                                    variant="outline"
                                    size="xs"
                                    disabled={userQuestionSets.page_number >=
                                        userQuestionSets.total_pages}
                                    onclick={() =>
                                        handlePageChange(
                                            userQuestionSets.page_number + 1,
                                        )}
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

        {#snippet changesSection()}
            {@const changes = getChangesInfo()}
            <div
                class="flex items-center justify-between pt-4 border-t border-base-300"
            >
                <div class="text-sm text-base-content/60">
                    {#if changes.toAdd.length > 0 || changes.toRemove.length > 0}
                        <div class="space-y-1">
                            {#if changes.toAdd.length > 0}
                                <div class="text-success">
                                    + Add to {changes.toAdd.length} set(s)
                                </div>
                            {/if}
                            {#if changes.toRemove.length > 0}
                                <div class="text-warning">
                                    - Remove from {changes.toRemove.length} set(s)
                                </div>
                            {/if}
                        </div>
                    {:else}
                        <span>No changes</span>
                    {/if}
                </div>

                <div class="flex gap-2">
                    <Button variant="ghost" onclick={closeModal}>Cancel</Button>
                    <Button
                        variant="primary"
                        onclick={handleModifySets}
                        disabled={changes.toAdd.length === 0 &&
                            changes.toRemove.length === 0}
                        class="gap-2"
                    >
                        <EditIcon class="h-4 w-4" />
                        Apply Changes
                    </Button>
                </div>
            </div>
        {/snippet}

        {@render changesSection()}
    </div>
</Modal>
