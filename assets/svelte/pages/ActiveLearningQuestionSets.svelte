<script>
    import { SearchIcon, PlusIcon, TrashIcon, EditIcon } from "lucide-svelte";
    import QuestionSetCard from "../components/questions/QuestionSetCard.svelte";
    import Button from "../components/Button.svelte";
    import TextInput from "../components/TextInput.svelte";
    import Modal from "../components/Modal.svelte";

    let { live, questionSets } = $props();

    let searchQuery = $state("");
    let isEditMode = $state(false);
    let selectedSetIds = $state(new Set());
    let showCreateModal = $state(false);
    let newSetTitle = $state("");
    let newSetDescription = $state("");
    let newSetIsPrivate = $state(true);

    let filteredQuestionSets = $derived(
        questionSets?.filter(
            (qs) =>
                qs.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
                qs.description?.toLowerCase().includes(searchQuery.toLowerCase()) ||
                qs.tags.some((tag) =>
                    tag.name.toLowerCase().includes(searchQuery.toLowerCase())
                )
        ) || []
    );

    function toggleEditMode() {
        isEditMode = !isEditMode;
        if (!isEditMode) {
            selectedSetIds.clear();
        }
    }

    function toggleSetSelection(setId) {
        if (selectedSetIds.has(setId)) {
            selectedSetIds.delete(setId);
        } else {
            selectedSetIds.add(setId);
        }
        selectedSetIds = new Set(selectedSetIds);
    }

    function selectAll() {
        const ownedSets = filteredQuestionSets.filter((qs) => qs.owner !== null);
        ownedSets.forEach((qs) => selectedSetIds.add(qs.id));
        selectedSetIds = new Set(selectedSetIds);
    }

    function clearSelection() {
        selectedSetIds.clear();
        selectedSetIds = new Set(selectedSetIds);
    }

    function handleBulkDelete() {
        if (selectedSetIds.size === 0) return;

        const message = `Are you sure you want to delete ${selectedSetIds.size} question set(s)? This action cannot be undone.`;
        if (confirm(message)) {
            const questionSetIdsArray = Array.from(selectedSetIds).map(String);
            live.pushEvent("bulk_delete_question_sets", {
                question_set_ids: questionSetIdsArray,
            });
            selectedSetIds.clear();
        }
    }

    function openCreateModal() {
        newSetTitle = "";
        newSetDescription = "";
        newSetIsPrivate = true;
        showCreateModal = true;
    }

    function closeCreateModal() {
        showCreateModal = false;
    }

    function handleCreateSet() {
        if (!newSetTitle.trim()) return;

        live.pushEvent("create_question_set", {
            title: newSetTitle.trim(),
            description: newSetDescription.trim(),
            is_private: newSetIsPrivate,
        });

        closeCreateModal();
    }
</script>

<div class="min-h-screen bg-base-100 p-4 md:p-6 lg:p-8">
    <div class="max-w-7xl mx-auto">
        <div class="mb-8">
            <div class="flex items-center justify-between mb-4">
                <div>
                    <h1 class="text-4xl font-bold text-base-content mb-2">
                        Question Sets
                    </h1>
                    <p class="text-base-content/70 text-lg">
                        Discover and practice with our collection of question sets
                    </p>
                </div>

                <div class="flex items-center gap-2">
                    <Button variant="primary" onclick={openCreateModal} class="gap-2">
                        <PlusIcon class="h-4 w-4" />
                        Create Set
                    </Button>

                    <Button
                        variant={isEditMode ? "error" : "outline"}
                        onclick={toggleEditMode}
                        class="gap-2"
                    >
                        <EditIcon class="h-4 w-4" />
                        {isEditMode ? "Exit Edit" : "Edit Mode"}
                    </Button>
                </div>
            </div>
        </div>

        <div class="mb-8 space-y-4">
            <div class="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
                <label for="search" class="input relative flex-1 max-w-md">
                    <SearchIcon class="h-5 w-5" />
                    <input
                        type="search"
                        bind:value={searchQuery}
                        placeholder="Search question sets..."
                        class="grow"
                    />
                </label>

                <div class="flex items-center gap-2 text-base-content/70">
                    <span class="text-sm">
                        {filteredQuestionSets.length} of {questionSets?.length || 0} sets
                    </span>
                </div>
            </div>

            {#if isEditMode}
                <div class="bg-warning/10 border border-warning/30 rounded-lg p-4">
                    <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                        <div class="flex items-center gap-4">
                            <span class="text-sm font-medium text-base-content">
                                {selectedSetIds.size} set(s) selected
                            </span>

                            <div class="flex gap-2">
                                <Button variant="outline" size="xs" onclick={selectAll}>
                                    Select All Owned
                                </Button>
                                <Button variant="ghost" size="xs" onclick={clearSelection}>
                                    Clear
                                </Button>
                            </div>
                        </div>

                        <div class="flex gap-2">
                            <Button
                                variant="error"
                                size="sm"
                                onclick={handleBulkDelete}
                                disabled={selectedSetIds.size === 0}
                                class="gap-2"
                            >
                                <TrashIcon class="h-4 w-4" />
                                Delete Selected
                            </Button>
                        </div>
                    </div>
                </div>
            {/if}
        </div>

        {#if filteredQuestionSets.length === 0}
            <div class="text-center py-16">
                <div class="w-24 h-24 mx-auto mb-4 bg-base-200 rounded-full flex items-center justify-center">
                    <svg
                        class="w-12 h-12 text-base-content/30"
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                        />
                    </svg>
                </div>
                <h3 class="text-xl font-semibold text-base-content mb-2">
                    No question sets found
                </h3>
                <p class="text-base-content/60">
                    Try adjusting your search or check back later for new content.
                </p>
            </div>
        {:else}
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                {#each filteredQuestionSets as questionSet (questionSet.id)}
                    {@const isSelected = selectedSetIds.has(questionSet.id)}
                    {@const canSelect = questionSet.owner !== null}

                    <div
                        class="h-full transition-all duration-200 {isEditMode && !canSelect
                            ? 'opacity-50'
                            : ''} {isEditMode && canSelect
                            ? 'cursor-pointer'
                            : ''}"
                        onclick={() => isEditMode && canSelect && toggleSetSelection(questionSet.id)}
                        onkeydown={(e) => e.key === "Enter" && isEditMode && canSelect && toggleSetSelection(questionSet.id)}
                        tabindex={isEditMode && canSelect ? 0 : undefined}
                        role={isEditMode && canSelect ? "button" : undefined}
                    >
                        <QuestionSetCard {questionSet} isSelected={isEditMode && isSelected} />
                    </div>
                {/each}
            </div>
        {/if}
    </div>
</div>

<Modal
    isOpen={showCreateModal}
    onClose={closeCreateModal}
    title="Create New Question Set"
    size="md"
>
    <div class="space-y-4">
        <TextInput
            bind:value={newSetTitle}
            label="Title"
            placeholder="Enter a title for your question set..."
            fullWidth={true}
            required={true}
        />

        <div class="form-control">
            <label for="newSetDescription" class="label">
                <span class="label-text">Description (optional)</span>
            </label>
            <textarea
                bind:value={newSetDescription}
                placeholder="Describe your question set..."
                class="textarea textarea-bordered w-full"
                rows="3"
            ></textarea>
        </div>

        <div class="form-control">
            <label class="cursor-pointer label">
                <span class="label-text">Visibility</span>
                <input
                    type="checkbox"
                    bind:checked={newSetIsPrivate}
                    class="toggle toggle-primary"
                />
            </label>
            <div class="label">
                <span class="label-text-alt text-base-content/60">
                    {newSetIsPrivate
                        ? "Private - Only you can see this set"
                        : "Public - Everyone can see this set"}
                </span>
            </div>
        </div>

        <div class="flex justify-end gap-2 pt-4">
            <Button variant="ghost" onclick={closeCreateModal}>Cancel</Button>
            <Button
                variant="primary"
                onclick={handleCreateSet}
                disabled={!newSetTitle.trim()}
            >
                Create Question Set
            </Button>
        </div>
    </div>
</Modal>
