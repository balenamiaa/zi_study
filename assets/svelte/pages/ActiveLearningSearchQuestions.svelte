<script>
    import {
        SearchIcon,
        FilterIcon,
        SettingsIcon,
        EditIcon,
        XIcon,
        PlusIcon,
        CheckIcon,
    } from "lucide-svelte";
    import QuestionRenderer from "../components/questions/QuestionRenderer.svelte";
    import Button from "../components/Button.svelte";
    import TextInput from "../components/TextInput.svelte";
    import Modal from "../components/Modal.svelte";
    import Badge from "../components/Badge.svelte";
    import { onMount, onDestroy } from "svelte";
    import BulkAddToSetsModal from "../components/questions/BulkAddToSetsModal.svelte";

    let {
        live,
        searchResults = [],
        searchConfig = {},
        isSearching = false,
        cursor = null,
        hasMore = false,
        selectedQuestionIds: selectedQuestionIdsArray = [],
        bulkSelectMode = false,
        userQuestionSets = null,
        currentUser,
    } = $props();

    // Search state
    let searchQuery = $state("");
    let showFilters = $state(false);
    let showSettings = $state(false);
    let searchInputEl = $state(null);

    // Filters
    let selectedTypes = $state(new Set());
    let selectedDifficulties = $state(new Set());
    let selectedScope = $state(new Set(["all"]));

    // Settings
    let caseSensitive = $state(false);
    let sortBy = $state("relevance");

    // Bulk selection
    let showBulkAddModal = $state(false);

    // Infinite scroll
    let loadMoreTrigger = $state(null);
    let observer = null;

    // Question types and difficulties
    const questionTypes = [
        { value: "mcq_single", label: "MCQ Single", color: "primary" },
        { value: "mcq_multi", label: "MCQ Multi", color: "secondary" },
        { value: "true_false", label: "True/False", color: "accent" },
        { value: "cloze", label: "Cloze", color: "info" },
        { value: "written", label: "Written", color: "success" },
        { value: "emq", label: "EMQ", color: "warning" },
    ];

    const difficulties = [
        { value: "easy", label: "Easy", color: "success" },
        { value: "medium", label: "Medium", color: "warning" },
        { value: "hard", label: "Hard", color: "error" },
    ];

    const searchScopes = [
        { value: "all", label: "All Fields" },
        { value: "question_text", label: "Question Text" },
        { value: "options", label: "Options/Choices" },
        { value: "answers", label: "Answers" },
        { value: "explanation", label: "Explanations" },
        { value: "retention_aid", label: "Retention Aids" },
    ];

    // Deduplicate search results by question ID
    let deduplicatedResults = $derived.by(() => {
        const seen = new Set();
        const deduplicated = [];

        for (const result of searchResults) {
            if (!seen.has(result.question.id)) {
                seen.add(result.question.id);
                deduplicated.push(result);
            }
        }

        return deduplicated;
    });

    // Debounced search
    const performSearch = () => {
        if (
            !searchQuery.trim() &&
            selectedTypes.size === 0 &&
            selectedDifficulties.size === 0
        ) {
            return;
        }

        const config = {
            search_scope: selectedScope.has("all")
                ? ["all"]
                : Array.from(selectedScope),
            case_sensitive: caseSensitive,
            sort_by: sortBy,
            question_types: Array.from(selectedTypes),
            difficulties: Array.from(selectedDifficulties),
        };

        live.pushEvent("search", { query: searchQuery, config });
    };

    $effect(() => {
        searchQuery; // Track
        selectedTypes.size; // Track
        selectedDifficulties.size; // Track
        selectedScope.size; // Track
        caseSensitive; // Track
        sortBy; // Track

        performSearch();
    });

    onMount(() => {
        if (searchInputEl) {
            searchInputEl.focus();
        }

        observer = new IntersectionObserver(
            (entries) => {
                if (entries[0].isIntersecting && hasMore && !isSearching) {
                    loadMore();
                }
            },
            { threshold: 0.1 },
        );

        if (loadMoreTrigger) {
            observer.observe(loadMoreTrigger);
        }
    });

    onDestroy(() => {
        if (observer && loadMoreTrigger) {
            observer.unobserve(loadMoreTrigger);
        }
    });

    function loadMore() {
        if (hasMore && !isSearching && searchQuery.trim()) {
            live.pushEvent("load_more", { query: searchQuery });
        }
    }

    function toggleBulkSelect() {
        live.pushEvent("toggle_bulk_select");
    }

    function toggleQuestionSelection(questionId) {
        if (bulkSelectMode) {
            live.pushEvent("toggle_question_selection", {
                question_id: String(questionId),
            });
        }
    }

    function selectAll() {
        live.pushEvent("select_all");
    }

    function clearSelection() {
        live.pushEvent("clear_selection");
    }

    function handleBulkAddToSets() {
        showBulkAddModal = true;
    }

    // Convert array from props to Set for easier handling
    let selectedQuestionIds = $derived(new Set(selectedQuestionIdsArray));

    function isQuestionSelected(questionId) {
        return selectedQuestionIds.has(questionId);
    }

    // Event handlers
    $effect(() => {
        if (!live) return;

        const openBulkAddHandle = live.handleEvent(
            "open_bulk_add_modal",
            ({ question_ids }) => {
                showBulkAddModal = true;
            },
        );

        return () => {
            live.removeHandleEvent(openBulkAddHandle);
        };
    });

    // Highlight text with search matches
    function highlightText(text, highlights) {
        if (!highlights || !text) return text;

        // If we have specific highlight data for this text, use it
        // Otherwise return the original text
        return highlights[text] || text;
    }

    function getActiveFiltersCount() {
        return selectedTypes.size + selectedDifficulties.size;
    }

    function getActiveSettingsCount() {
        let count = 0;
        if (caseSensitive) count++;
        if (sortBy !== "relevance") count++;
        if (!selectedScope.has("all")) count++;
        return count;
    }

    function clearAllFilters() {
        selectedTypes.clear();
        selectedDifficulties.clear();
        selectedScope.clear();
        selectedScope.add("all");
        selectedTypes = new Set(selectedTypes);
        selectedDifficulties = new Set(selectedDifficulties);
        selectedScope = new Set(selectedScope);
    }
</script>

<div class="min-h-screen bg-base-100 p-4 md:p-6 lg:p-8">
    <div class="max-w-7xl mx-auto">
        <!-- Header -->
        <div class="mb-8">
            <div class="flex items-center justify-between mb-4">
                <div>
                    <h1
                        class="text-3xl sm:text-4xl font-bold text-base-content mb-2"
                    >
                        Search Questions
                    </h1>
                    <p class="text-base-content/70 text-base sm:text-lg">
                        Search through all questions with advanced filters and
                        highlighting
                    </p>
                </div>

                {#if deduplicatedResults.length > 0}
                    <Button
                        variant={bulkSelectMode ? "error" : "outline"}
                        onclick={toggleBulkSelect}
                        class="gap-2"
                    >
                        <EditIcon class="h-4 w-4" />
                        {bulkSelectMode ? "Exit Selection" : "Bulk Select"}
                    </Button>
                {/if}
            </div>

            <!-- Search Bar -->
            <div class="relative">
                <TextInput
                    bind:this={searchInputEl}
                    bind:value={searchQuery}
                    placeholder="Search questions..."
                    fullWidth={true}
                    size="lg"
                    variant="bordered"
                    icon={SearchIcon}
                    type="search"
                />

                <!-- Filter/Settings Buttons -->
                <div
                    class="absolute top-1/2 -translate-y-1/2 right-4 flex gap-2"
                >
                    <div class="tooltip tooltip-bottom" data-tip="Filters">
                        <button
                            class="btn btn-circle btn-ghost relative {showFilters
                                ? 'btn-active'
                                : ''}"
                            onclick={() => (showFilters = !showFilters)}
                            aria-label="Toggle filters"
                        >
                            <FilterIcon class="h-5 w-5" />
                            {#if getActiveFiltersCount() > 0}
                                <span
                                    class="absolute -top-1 -right-1 badge badge-primary badge-xs"
                                >
                                    {getActiveFiltersCount()}
                                </span>
                            {/if}
                        </button>
                    </div>
                    <div
                        class="tooltip tooltip-bottom"
                        data-tip="Search Settings"
                    >
                        <button
                            class="btn btn-circle btn-ghost {showSettings
                                ? 'btn-active'
                                : ''}"
                            onclick={() => (showSettings = !showSettings)}
                            aria-label="Toggle search settings"
                        >
                            <SettingsIcon class="h-5 w-5" />
                            {#if getActiveSettingsCount() > 0}
                                <span
                                    class="absolute -top-1 -right-1 badge badge-primary badge-xs"
                                >
                                    {getActiveSettingsCount()}
                                </span>
                            {/if}
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Filters Panel -->
        {#if showFilters}
            <div class="bg-base-200 rounded-lg p-6 mb-6 space-y-4">
                <div class="flex items-center justify-between mb-4">
                    <h3 class="text-lg font-semibold">Filters</h3>
                    {#if getActiveFiltersCount() > 0}
                        <Button
                            variant="ghost"
                            size="sm"
                            onclick={clearAllFilters}
                        >
                            Clear All
                        </Button>
                    {/if}
                </div>

                <!-- Question Types -->
                <div>
                    <div class="text-sm font-medium mb-2">Question Types</div>
                    <div class="flex flex-wrap gap-2">
                        {#each questionTypes as type}
                            <label class="cursor-pointer">
                                <input
                                    type="checkbox"
                                    checked={selectedTypes.has(type.value)}
                                    onchange={() => {
                                        if (selectedTypes.has(type.value)) {
                                            selectedTypes.delete(type.value);
                                        } else {
                                            selectedTypes.add(type.value);
                                        }
                                        selectedTypes = new Set(selectedTypes);
                                    }}
                                    class="hidden"
                                />
                                <Badge
                                    variant={selectedTypes.has(type.value)
                                        ? type.color
                                        : "neutral"}
                                    class="cursor-pointer hover:opacity-80 transition-opacity"
                                >
                                    {type.label}
                                </Badge>
                            </label>
                        {/each}
                    </div>
                </div>

                <!-- Difficulties -->
                <div>
                    <div class="text-sm font-medium mb-2">Difficulty</div>
                    <div class="flex flex-wrap gap-2">
                        {#each difficulties as diff}
                            <label class="cursor-pointer">
                                <input
                                    type="checkbox"
                                    checked={selectedDifficulties.has(
                                        diff.value,
                                    )}
                                    onchange={() => {
                                        if (
                                            selectedDifficulties.has(diff.value)
                                        ) {
                                            selectedDifficulties.delete(
                                                diff.value,
                                            );
                                        } else {
                                            selectedDifficulties.add(
                                                diff.value,
                                            );
                                        }
                                        selectedDifficulties = new Set(
                                            selectedDifficulties,
                                        );
                                    }}
                                    class="hidden"
                                />
                                <Badge
                                    variant={selectedDifficulties.has(
                                        diff.value,
                                    )
                                        ? diff.color
                                        : "neutral"}
                                    class="cursor-pointer hover:opacity-80 transition-opacity"
                                >
                                    {diff.label}
                                </Badge>
                            </label>
                        {/each}
                    </div>
                </div>
            </div>
        {/if}

        <!-- Settings Panel -->
        {#if showSettings}
            <div class="bg-base-200 rounded-lg p-6 mb-6 space-y-4">
                <h3 class="text-lg font-semibold mb-4">Search Settings</h3>

                <!-- Search Scope -->
                <div>
                    <div class="text-sm font-medium mb-2">Search Scope</div>
                    <div class="flex flex-wrap gap-2">
                        {#each searchScopes as scope}
                            <label class="cursor-pointer">
                                <input
                                    type="checkbox"
                                    checked={selectedScope.has(scope.value)}
                                    onchange={() => {
                                        if (scope.value === "all") {
                                            selectedScope.clear();
                                            selectedScope.add("all");
                                        } else {
                                            selectedScope.delete("all");
                                            if (
                                                selectedScope.has(scope.value)
                                            ) {
                                                selectedScope.delete(
                                                    scope.value,
                                                );
                                            } else {
                                                selectedScope.add(scope.value);
                                            }
                                            if (selectedScope.size === 0) {
                                                selectedScope.add("all");
                                            }
                                        }
                                        selectedScope = new Set(selectedScope);
                                    }}
                                    class="hidden"
                                />
                                <Badge
                                    variant={selectedScope.has(scope.value)
                                        ? "info"
                                        : "neutral"}
                                    class="cursor-pointer hover:opacity-80 transition-opacity"
                                >
                                    {scope.label}
                                </Badge>
                            </label>
                        {/each}
                    </div>
                </div>

                <!-- Case Sensitivity -->
                <div class="form-control">
                    <label class="label cursor-pointer justify-start gap-3">
                        <input
                            type="checkbox"
                            bind:checked={caseSensitive}
                            class="checkbox checkbox-primary"
                        />
                        <span class="label-text">Case sensitive search</span>
                    </label>
                </div>

                <!-- Sort Order -->
                <div>
                    <div class="text-sm font-medium mb-2">Sort By</div>
                    <select
                        bind:value={sortBy}
                        class="select select-bordered w-full max-w-xs"
                    >
                        <option value="relevance">Relevance</option>
                        <option value="newest">Newest First</option>
                        <option value="oldest">Oldest First</option>
                    </select>
                </div>
            </div>
        {/if}

        <!-- Bulk Selection Bar -->
        {#if bulkSelectMode && deduplicatedResults.length > 0}
            <div
                class="bg-warning/10 border border-warning/30 rounded-lg p-4 mb-6"
            >
                <div class="flex items-center justify-between flex-wrap gap-4">
                    <div class="flex items-center gap-4">
                        <span class="text-sm font-medium">
                            {selectedQuestionIds.size} question(s) selected
                        </span>
                        <div class="flex gap-2">
                            <Button
                                variant="outline"
                                size="xs"
                                onclick={selectAll}
                            >
                                Select All
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

                    <Button
                        variant="primary"
                        size="sm"
                        onclick={handleBulkAddToSets}
                        disabled={selectedQuestionIds.size === 0}
                        class="gap-2"
                    >
                        <PlusIcon class="h-4 w-4" />
                        Add to Sets
                    </Button>
                </div>
            </div>
        {/if}

        <!-- Search Results -->
        <div class="space-y-6">
            {#if isSearching && deduplicatedResults.length === 0}
                <div class="text-center py-12">
                    <div
                        class="loading loading-spinner loading-lg text-primary"
                    ></div>
                    <p class="mt-4 text-base-content/60">Searching...</p>
                </div>
            {:else if deduplicatedResults.length === 0 && searchQuery}
                <div class="text-center py-12">
                    <SearchIcon
                        class="h-16 w-16 text-base-content/20 mx-auto mb-4"
                    />
                    <h3 class="text-xl font-semibold mb-2">No results found</h3>
                    <p class="text-base-content/60">
                        Try adjusting your search query or filters
                    </p>
                </div>
            {:else if deduplicatedResults.length === 0}
                <div class="text-center py-12">
                    <SearchIcon
                        class="h-16 w-16 text-base-content/20 mx-auto mb-4"
                    />
                    <h3 class="text-xl font-semibold mb-2">Start searching</h3>
                    <p class="text-base-content/60">
                        Enter a search query to find questions
                    </p>
                </div>
            {:else}
                <div class="text-sm text-base-content/60 mb-4">
                    Found {deduplicatedResults.length} unique question{deduplicatedResults.length ===
                    1
                        ? ""
                        : "s"}
                </div>

                {#each deduplicatedResults as result, index (`${result.question.id}-${index}`)}
                    {@const isSelected = isQuestionSelected(result.question.id)}

                    <!-- svelte-ignore a11y_no_noninteractive_tabindex -->
                    <div
                        class="relative transition-all duration-200 {bulkSelectMode
                            ? 'cursor-pointer hover:scale-[1.01]'
                            : ''} {isSelected
                            ? 'ring-2 ring-primary shadow-lg'
                            : ''}"
                        onclick={() =>
                            toggleQuestionSelection(result.question.id)}
                        onkeydown={(e) =>
                            e.key === "Enter" &&
                            toggleQuestionSelection(result.question.id)}
                        role={bulkSelectMode ? "button" : undefined}
                        tabindex={bulkSelectMode ? 0 : undefined}
                    >
                        {#if bulkSelectMode}
                            <div class="absolute -top-2 -right-2 z-10">
                                <div
                                    class="w-8 h-8 rounded-full flex items-center justify-center {isSelected
                                        ? 'bg-primary text-primary-content shadow-md'
                                        : 'bg-base-300 border-2 border-base-content/20'}"
                                >
                                    {#if isSelected}
                                        <CheckIcon class="h-5 w-5" />
                                    {/if}
                                </div>
                            </div>
                        {/if}

                        <!-- Search snippet/preview -->
                        {#if result.snippet && !bulkSelectMode}
                            <div
                                class="mb-2 p-3 bg-base-200 rounded-lg text-sm text-base-content/70"
                            >
                                <div class="line-clamp-2">
                                    {@html result.snippet}
                                </div>
                            </div>
                        {/if}

                        <QuestionRenderer
                            question={result.question}
                            questionNumber={index + 1}
                            userAnswer={result.answer}
                            {live}
                            {userQuestionSets}
                            isActive={false}
                        />
                    </div>
                {/each}

                <!-- Load More Trigger -->
                <div
                    bind:this={loadMoreTrigger}
                    class="h-20 flex items-center justify-center"
                >
                    {#if isSearching}
                        <div
                            class="loading loading-spinner loading-md text-primary"
                        ></div>
                    {:else if hasMore}
                        <Button variant="outline" onclick={loadMore}>
                            Load More
                        </Button>
                    {:else if deduplicatedResults.length > 0}
                        <p class="text-sm text-base-content/50">
                            End of results
                        </p>
                    {/if}
                </div>
            {/if}
        </div>
    </div>
</div>

<!-- Bulk Add to Sets Modal -->
{#if showBulkAddModal}
    <BulkAddToSetsModal
        isOpen={showBulkAddModal}
        onClose={() => (showBulkAddModal = false)}
        questionIds={Array.from(selectedQuestionIds)}
        {userQuestionSets}
        {live}
        {currentUser}
    />
{/if}
