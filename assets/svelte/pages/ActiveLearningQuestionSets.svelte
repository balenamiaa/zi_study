<script>
    import {
        SearchIcon,
        PlusIcon,
        TrashIcon,
        EditIcon,
        FilterIcon,
        XIcon,
        TagIcon,
        UserIcon,
    } from "lucide-svelte";
    import QuestionSetCard from "../components/questions/QuestionSetCard.svelte";
    import Button from "../components/Button.svelte";
    import TextInput from "../components/TextInput.svelte";
    import Modal from "../components/Modal.svelte";

    let { live, questionSets, availableTags, currentUser } = $props();

    let searchQuery = $state("");
    let isEditMode = $state(false);
    let selectedSetIds = $state(new Set());
    let showCreateModal = $state(false);
    let newSetTitle = $state("");
    let newSetDescription = $state("");
    let newSetIsPrivate = $state(true);
    let showFilters = $state(false);
    let selectedTags = $state(new Set());
    let ownedOnly = $state(false);
    let tagSearch = $state("");

    let filteredAvailableTags = $derived(
        availableTags?.filter((tag) =>
            tag.name.toLowerCase().includes(tagSearch.toLowerCase()),
        ) || [],
    );

    let filteredQuestionSets = $derived.by(() => {
        if (!questionSets) return [];

        return questionSets.filter((qs) => {
            // Text search
            const matchesSearch =
                searchQuery === "" ||
                qs.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
                qs.description
                    ?.toLowerCase()
                    .includes(searchQuery.toLowerCase()) ||
                qs.tags.some((tag) =>
                    tag.name.toLowerCase().includes(searchQuery.toLowerCase()),
                );

            // Tag filter
            const matchesTags =
                selectedTags.size === 0 ||
                qs.tags.some((tag) => selectedTags.has(tag.id));

            // Ownership filter
            const matchesOwnership =
                !ownedOnly ||
                (qs.owner !== null && qs.owner.email === currentUser.email);

            return matchesSearch && matchesTags && matchesOwnership;
        });
    });

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
        const ownedSets = filteredQuestionSets.filter(
            (qs) => qs.owner !== null && qs.owner.email === currentUser.email,
        );
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

    function toggleTagFilter(tagId) {
        if (selectedTags.has(tagId)) {
            selectedTags.delete(tagId);
        } else {
            selectedTags.add(tagId);
        }
        selectedTags = new Set(selectedTags);
    }

    function clearAllFilters() {
        selectedTags.clear();
        selectedTags = new Set(selectedTags);
        ownedOnly = false;
        tagSearch = "";
    }

    let activeFiltersCount = $derived(selectedTags.size + (ownedOnly ? 1 : 0));
</script>

<div class="min-h-screen bg-base-100 p-4 md:p-6 lg:p-8">
    <div class="max-w-8xl mx-auto">
        <!-- Header Section -->
        <div class="mb-8 relative">
            <!-- Action buttons positioned absolutely on mobile -->
            <div
                class="absolute top-0 right-0 flex flex-col sm:flex-row gap-2 z-10"
            >
                <Button
                    variant="primary"
                    onclick={openCreateModal}
                    class="btn-sm gap-2"
                >
                    <PlusIcon class="h-4 w-4" />
                    <span class="hidden sm:inline">Create Set</span>
                </Button>

                <Button
                    variant={isEditMode ? "error" : "outline"}
                    onclick={toggleEditMode}
                    class="btn-sm gap-2"
                >
                    <EditIcon class="h-4 w-4" />
                    <span class="hidden sm:inline"
                        >{isEditMode ? "Exit Edit" : "Edit Mode"}</span
                    >
                </Button>
            </div>

            <!-- Title and description with right padding for buttons -->
            <div class="pr-24 sm:pr-0">
                <h1
                    class="text-3xl sm:text-4xl font-bold text-base-content mb-2"
                >
                    Question Sets
                </h1>
                <p class="text-base-content/70 text-base sm:text-lg">
                    Discover and practice with our collection of question sets
                </p>
            </div>
        </div>

        <!-- Search and Filters Section -->
        <div class="mb-8 space-y-4">
            <div
                class="flex flex-col lg:flex-row gap-4 items-start lg:items-center"
            >
                <!-- Search Input -->
                <div class="flex-1 w-full lg:max-w-lg">
                    <label for="search" class="input input-lg relative w-full">
                        <SearchIcon class="h-5 w-5" />
                        <input
                            type="search"
                            bind:value={searchQuery}
                            placeholder="Search question sets..."
                            class="grow text-base"
                        />
                    </label>
                </div>

                <!-- Filters and Results -->
                <div
                    class="flex flex-col sm:flex-row items-start sm:items-center gap-4 w-full lg:w-auto"
                >
                    <button
                        class="btn btn-outline gap-2 w-full sm:w-auto"
                        onclick={() => (showFilters = !showFilters)}
                    >
                        <FilterIcon class="h-4 w-4" />
                        Filters
                        {#if activeFiltersCount > 0}
                            <span class="badge badge-primary badge-sm"
                                >{activeFiltersCount}</span
                            >
                        {/if}
                        {#if showFilters}
                            <svg
                                class="w-4 h-4"
                                xmlns="http://www.w3.org/2000/svg"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M5 15l7-7 7 7"
                                />
                            </svg>
                        {:else}
                            <svg
                                class="w-4 h-4"
                                xmlns="http://www.w3.org/2000/svg"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M19 9l-7 7-7-7"
                                />
                            </svg>
                        {/if}
                    </button>

                    <div class="text-sm text-base-content/70 whitespace-nowrap">
                        {filteredQuestionSets.length} of {questionSets?.length ||
                            0} sets
                    </div>
                </div>
            </div>

            <!-- Filters Panel -->
            {#if showFilters}
                <div
                    class="bg-base-200 rounded-lg p-4 border border-base-300 space-y-4"
                >
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-semibold text-base-content">
                            Filters
                        </h3>
                        {#if activeFiltersCount > 0}
                            <button
                                class="btn btn-ghost btn-sm gap-2"
                                onclick={clearAllFilters}
                            >
                                <XIcon class="h-4 w-4" />
                                Clear All
                            </button>
                        {/if}
                    </div>

                    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                        <!-- Tags Filter -->
                        <div class="space-y-3">
                            <div class="flex items-center gap-2">
                                <TagIcon class="h-4 w-4 text-base-content/70" />
                                <span class="font-medium text-base-content"
                                    >Tags</span
                                >
                                {#if selectedTags.size > 0}
                                    <span class="badge badge-primary badge-sm"
                                        >{selectedTags.size}</span
                                    >
                                {/if}
                            </div>

                            <div class="space-y-2">
                                <input
                                    type="search"
                                    bind:value={tagSearch}
                                    placeholder="Search tags..."
                                    class="input input-sm input-bordered w-full"
                                />

                                <div class="max-h-32 overflow-y-auto">
                                    <div class="flex flex-wrap gap-2 p-1">
                                        {#each filteredAvailableTags as tag (tag.id)}
                                            <button
                                                class="px-3 py-1.5 text-xs font-medium rounded-full transition-all duration-200 border min-h-8 whitespace-nowrap hover:-translate-y-0.5 {selectedTags.has(
                                                    tag.id,
                                                )
                                                    ? 'bg-primary text-primary-content border-primary shadow-md'
                                                    : 'bg-base-200 text-base-content/70 border-base-300 hover:bg-primary/10 hover:text-primary hover:border-primary/30 shadow-sm'}"
                                                onclick={() =>
                                                    toggleTagFilter(tag.id)}
                                            >
                                                {tag.name}
                                            </button>
                                        {:else}
                                            <div
                                                class="text-sm text-base-content/50 italic py-2 w-full text-center"
                                            >
                                                {tagSearch
                                                    ? "No tags found"
                                                    : "No tags available"}
                                            </div>
                                        {/each}
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Ownership Filter -->
                        <div class="space-y-3">
                            <div class="flex items-center gap-2">
                                <UserIcon
                                    class="h-4 w-4 text-base-content/70"
                                />
                                <span class="font-medium text-base-content"
                                    >Ownership</span
                                >
                            </div>

                            <label
                                class="cursor-pointer label justify-start gap-3"
                            >
                                <input
                                    type="checkbox"
                                    bind:checked={ownedOnly}
                                    class="checkbox checkbox-primary"
                                />
                                <span class="label-text"
                                    >Show only sets I own</span
                                >
                            </label>
                        </div>
                    </div>
                </div>
            {/if}

            <!-- Edit Mode Panel -->
            {#if isEditMode}
                <div
                    class="bg-warning/10 border border-warning/30 rounded-lg p-4"
                >
                    <div
                        class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4"
                    >
                        <div class="flex items-center gap-4">
                            <span class="text-sm font-medium text-base-content">
                                {selectedSetIds.size} set(s) selected
                            </span>

                            <div class="flex gap-2">
                                <Button
                                    variant="outline"
                                    size="xs"
                                    onclick={selectAll}
                                >
                                    Select All Owned
                                </Button>
                                <Button
                                    variant="ghost"
                                    size="xs"
                                    onclick={clearSelection}
                                >
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

        <!-- Question Sets Grid -->
        {#if filteredQuestionSets.length === 0}
            <div class="text-center py-16">
                <div
                    class="w-24 h-24 mx-auto mb-4 bg-base-200 rounded-full flex items-center justify-center"
                >
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
                    {activeFiltersCount > 0
                        ? "Try adjusting your filters or search criteria."
                        : "Try adjusting your search or check back later for new content."}
                </p>
            </div>
        {:else}
            <div
                class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
            >
                {#each filteredQuestionSets as questionSet (questionSet.id)}
                    {@const isSelected = selectedSetIds.has(questionSet.id)}
                    {@const canSelect =
                        questionSet.owner !== null &&
                        questionSet.owner.email === currentUser.email}

                    <div
                        class="h-full transition-all duration-200 {isEditMode &&
                        !canSelect
                            ? 'opacity-50'
                            : ''} {isEditMode && canSelect
                            ? 'cursor-pointer'
                            : ''}"
                        onclick={() =>
                            isEditMode &&
                            canSelect &&
                            toggleSetSelection(questionSet.id)}
                        onkeydown={(e) =>
                            e.key === "Enter" &&
                            isEditMode &&
                            canSelect &&
                            toggleSetSelection(questionSet.id)}
                        tabindex="0"
                        role="button"
                    >
                        <QuestionSetCard
                            {questionSet}
                            isSelected={isEditMode && isSelected}
                            enableNavigation={!isEditMode}
                        />
                    </div>
                {/each}
            </div>
        {/if}
    </div>
</div>

<!-- Create Modal -->
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
