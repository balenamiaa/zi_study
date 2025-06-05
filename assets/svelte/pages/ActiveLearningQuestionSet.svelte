<script>
    import { SearchIcon, PlusIcon, CheckIcon } from "lucide-svelte";
    import FilterPanel from "../components/questions/FilterPanel.svelte";
    import QuestionsOverview from "../components/questions/QuestionsOverview.svelte";
    import QuestionRenderer from "../components/questions/QuestionRenderer.svelte";
    import InlineEdit from "../components/InlineEdit.svelte";
    import Button from "../components/Button.svelte";
    let { live, questionSet, userQuestionSets, questions, currentUser } = $props();

    // State for filtering and searching
    let searchQuery = $state("");
    let showFilters = $state(false);
    let difficultyRange = $state([1, 5]);
    let answerStatus = $state("all"); // 'all', 'answered', 'unanswered'
    let currentQuestionIndex = $state(0);
    
    // State for question adding
    let showAddQuestions = $state(false);
    let addQuestionsSearch = $state("");
    let selectedQuestionIds = $state(new Set());
    let currentAddQuestionsPage = $state(1);

    // Questions container reference for scrolling
    let questionsContainer;

    // Filtered questions based on search and filters
    let filteredQuestions = $derived.by(() => {
        if (!questionSet?.questions) return [];

        return questionSet.questions.filter((question) => {
            // Search filter
            const matchesSearch =
                searchQuery === "" ||
                question.data.question_text
                    ?.toLowerCase()
                    .includes(searchQuery.toLowerCase());

            // Difficulty filter
            const difficulty = parseInt(question.data.difficulty) || 3;
            const matchesDifficulty =
                difficulty >= difficultyRange[0] &&
                difficulty <= difficultyRange[1];

            // Answer status filter (for now, treating all as unanswered since we don't have user answers yet)
            const matchesAnswerStatus =
                answerStatus === "all" || answerStatus === "unanswered"; // For demo purposes

            return matchesSearch && matchesDifficulty && matchesAnswerStatus;
        });
    });

    // Function to handle slider change
    function handleSliderChange(index) {
        currentQuestionIndex = index;
        scrollToQuestion(index);
    }

    // Function to scroll to specific question
    function scrollToQuestion(index) {
        if (questionsContainer && filteredQuestions[index]) {
            // Find the specific question element within the container
            const questionsWrapper = questionsContainer.children[0]; // max-w-4xl mx-auto div
            if (questionsWrapper && questionsWrapper.children[index]) {
                const questionElement = questionsWrapper.children[index];

                // Calculate the position relative to the container
                const containerRect =
                    questionsContainer.getBoundingClientRect();
                const elementRect = questionElement.getBoundingClientRect();
                const relativeTop =
                    elementRect.top -
                    containerRect.top +
                    questionsContainer.scrollTop;

                // Scroll within the container
                questionsContainer.scrollTo({
                    top: relativeTop - 20, // 20px offset for better visibility
                    behavior: "smooth",
                });
            }
        }
    }

    // Function to detect which question is currently in view
    function detectCurrentQuestion() {
        if (!questionsContainer || filteredQuestions.length === 0) return;

        const containerRect = questionsContainer.getBoundingClientRect();
        const containerMidpoint = containerRect.top + containerRect.height / 2;

        const questionsWrapper = questionsContainer.children[0];
        if (!questionsWrapper) return;

        let closestIndex = 0;
        let closestDistance = Infinity;

        // Check each question element
        for (let i = 0; i < questionsWrapper.children.length; i++) {
            const questionElement = questionsWrapper.children[i];
            const questionRect = questionElement.getBoundingClientRect();
            const questionMidpoint = questionRect.top + questionRect.height / 2;
            const distance = Math.abs(questionMidpoint - containerMidpoint);

            if (distance < closestDistance) {
                closestDistance = distance;
                closestIndex = i;
            }
        }

        // Only update if the index has changed
        if (closestIndex !== currentQuestionIndex) {
            currentQuestionIndex = closestIndex;
        }
    }

    // Throttled scroll handler
    let scrollTimeout;
    function handleScroll() {
        clearTimeout(scrollTimeout);
        scrollTimeout = setTimeout(detectCurrentQuestion, 100);
    }

    // Functions for inline editing
    function handleFieldUpdate(field, value) {
        live.pushEvent("update_question_set", { field, value });
    }

    // Functions for adding questions
    function toggleAddQuestions() {
        showAddQuestions = !showAddQuestions;
        if (showAddQuestions) {
            loadAvailableQuestions();
        } else {
            live.pushEvent("clear_questions");
        }
    }

    function loadAvailableQuestions() {
        live.pushEvent("load_questions", {
            page_number: currentAddQuestionsPage,
            search_query: addQuestionsSearch,
        });
    }

    function handleAddQuestionsSearch() {
        currentAddQuestionsPage = 1;
        loadAvailableQuestions();
    }

    function handleAddQuestionsPageChange(page) {
        currentAddQuestionsPage = page;
        loadAvailableQuestions();
    }

    function toggleQuestionSelection(questionId) {
        if (selectedQuestionIds.has(questionId)) {
            selectedQuestionIds.delete(questionId);
        } else {
            selectedQuestionIds.add(questionId);
        }
        selectedQuestionIds = new Set(selectedQuestionIds); // Trigger reactivity
    }

    function selectAllQuestions() {
        if (questions?.items) {
            questions.items.forEach(q => selectedQuestionIds.add(q.id));
            selectedQuestionIds = new Set(selectedQuestionIds);
        }
    }

    function clearQuestionSelection() {
        selectedQuestionIds.clear();
        selectedQuestionIds = new Set(selectedQuestionIds);
    }

    function handleAddSelectedQuestions() {
        if (selectedQuestionIds.size === 0) return;

        const questionIdsArray = Array.from(selectedQuestionIds).map(String);
        live.pushEvent("add_questions_to_set", {
            question_ids: questionIdsArray
        });
        
        selectedQuestionIds.clear();
    }
</script>

<div class="min-h-screen bg-base-100 flex flex-col gap-4">
    <!-- Header -->
    <div class="bg-base-200 border-b border-base-300">
        <div class="max-w-7xl mx-auto p-2 md:p-4">
            <div class="flex items-start justify-between mb-4">
                <div class="flex-1 mr-4">
                    <!-- Editable Title -->
                    <div class="mb-2">
                        <InlineEdit
                            bind:value={questionSet.title}
                            placeholder="Question Set Title"
                            type="text"
                            disabled={!questionSet?.owner || questionSet.owner.email !== currentUser?.email}
                            onSave={(value) => handleFieldUpdate("title", value)}
                            class="text-3xl font-bold text-base-content"
                        />
                    </div>

                    <!-- Editable Description -->
                    <div class="mt-2">
                        <InlineEdit
                            bind:value={questionSet.description}
                            placeholder="Add a description..."
                            type="textarea"
                            disabled={!questionSet?.owner || questionSet.owner.email !== currentUser?.email}
                            onSave={(value) => handleFieldUpdate("description", value)}
                            class="text-base-content/70"
                        />
                    </div>
                </div>

                <!-- Editable Privacy Toggle -->
                <div class="flex flex-col items-end gap-2">
                    <InlineEdit
                        bind:value={questionSet.is_private}
                        type="boolean"
                        disabled={!questionSet?.owner || questionSet.owner.email !== currentUser?.email}
                        onSave={(value) => handleFieldUpdate("is_private", value)}
                    />
                    
                    {#if questionSet?.owner}
                        <div class="text-xs text-base-content/50">
                            by {questionSet.owner.email}
                        </div>
                    {/if}
                </div>
            </div>

            <!-- Tags -->
            {#if questionSet?.tags && questionSet.tags.length > 0}
                <div class="flex flex-wrap gap-2">
                    {#each questionSet.tags as tag}
                        <span class="badge badge-outline">{tag.name}</span>
                    {/each}
                </div>
            {/if}
        </div>
    </div>

    <!-- Search and Filters -->
    <div class="bg-base-100 border-b border-base-300">
        <div class="max-w-7xl mx-auto p-2 md:p-4">
            <div
                class="flex flex-col sm:flex-row gap-4 items-start sm:items-center"
            >
                <!-- Search -->
                <label for="search" class="input relative flex-1 max-w-md">
                    <SearchIcon class="h-5 w-5" />
                    <input
                        type="search"
                        bind:value={searchQuery}
                        placeholder="Search questions..."
                        class="grow"
                    />
                </label>

                <!-- Filters Button -->
                <button
                    class="btn btn-outline gap-2 min-w-fit"
                    onclick={() => (showFilters = !showFilters)}
                >
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
                            d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.414A1 1 0 013 6.707V4z"
                        />
                    </svg>
                    All Filters
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

                <!-- Results count -->
                <div class="text-sm text-base-content/70 min-w-fit">
                    {filteredQuestions.length} of {questionSet?.questions
                        ?.length || 0} questions
                </div>
            </div>

            <!-- Filter Panel -->
            {#if showFilters}
                <div class="mt-4 border-t border-base-300 pt-4">
                    <FilterPanel bind:difficultyRange bind:answerStatus />
                </div>
            {/if}
        </div>
    </div>

    <!-- Questions Overview -->
    {#if questionSet}
        <QuestionsOverview
            {questionSet}
            {filteredQuestions}
            bind:currentQuestionIndex
            {handleSliderChange}
        />
    {/if}

    <!-- Add Questions Section -->
    {#if questionSet?.owner && questionSet.owner.email === currentUser?.email}
        <div class="bg-base-100 border-b border-base-300">
            <div class="max-w-7xl mx-auto p-2 md:p-4">
                <div class="flex items-center justify-between">
                    <h3 class="text-lg font-semibold text-base-content">
                        Manage Questions
                    </h3>
                    <Button
                        variant={showAddQuestions ? "error" : "primary"}
                        onclick={toggleAddQuestions}
                        class="gap-2"
                    >
                        <PlusIcon class="h-4 w-4" />
                        {showAddQuestions ? "Cancel" : "Add Questions"}
                    </Button>
                </div>

                {#if showAddQuestions}
                    <div class="mt-4 space-y-4">
                        <!-- Search for questions -->
                        <div class="flex flex-col sm:flex-row gap-4">
                            <label for="add-questions-search" class="input relative flex-1">
                                <SearchIcon class="h-5 w-5" />
                                <input
                                    type="search"
                                    bind:value={addQuestionsSearch}
                                    oninput={handleAddQuestionsSearch}
                                    placeholder="Search available questions..."
                                    class="grow"
                                />
                            </label>
                        </div>

                        <!-- Questions List -->
                        <div class="border border-base-300 rounded-lg">
                            {#if !questions}
                                <div class="p-8 text-center">
                                    <div class="loading loading-spinner loading-md text-primary"></div>
                                    <p class="mt-2 text-base-content/60">Loading questions...</p>
                                </div>
                            {:else if questions.items.length === 0}
                                <div class="p-8 text-center">
                                    <div class="w-16 h-16 mx-auto mb-3 bg-base-200 rounded-full flex items-center justify-center">
                                        <SearchIcon class="h-8 w-8 text-base-content/30" />
                                    </div>
                                    <h4 class="font-medium text-base-content mb-1">No questions found</h4>
                                    <p class="text-sm text-base-content/60">
                                        {addQuestionsSearch ? "Try a different search term" : "All questions are already in this set"}
                                    </p>
                                </div>
                            {:else}
                                <!-- Selection controls -->
                                <div class="bg-base-200 p-3 border-b border-base-300">
                                    <div class="flex items-center justify-between">
                                        <div class="flex items-center gap-4">
                                            <span class="text-sm font-medium">
                                                {selectedQuestionIds.size} of {questions.items.length} selected
                                            </span>
                                            <div class="flex gap-2">
                                                <Button variant="outline" size="xs" onclick={selectAllQuestions}>
                                                    Select All
                                                </Button>
                                                <Button variant="ghost" size="xs" onclick={clearQuestionSelection}>
                                                    Clear
                                                </Button>
                                            </div>
                                        </div>
                                        <Button
                                            variant="primary"
                                            size="sm"
                                            onclick={handleAddSelectedQuestions}
                                            disabled={selectedQuestionIds.size === 0}
                                            class="gap-2"
                                        >
                                            <PlusIcon class="h-4 w-4" />
                                            Add {selectedQuestionIds.size} Question(s)
                                        </Button>
                                    </div>
                                </div>

                                <!-- Questions list -->
                                <div class="max-h-80 overflow-y-auto">
                                    {#each questions.items as question (question.id)}
                                        {@const isSelected = selectedQuestionIds.has(question.id)}
                                        <div
                                            class="flex items-center gap-3 p-3 border-b border-base-300 last:border-b-0 hover:bg-base-50 transition-colors cursor-pointer"
                                            onclick={() => toggleQuestionSelection(question.id)}
                                        >
                                            <input
                                                type="checkbox"
                                                checked={isSelected}
                                                onchange={() => toggleQuestionSelection(question.id)}
                                                class="checkbox checkbox-primary checkbox-sm"
                                            />

                                            <div class="flex-1 min-w-0">
                                                <p class="font-medium text-base-content line-clamp-2">
                                                    {question.data.question_text || "Untitled Question"}
                                                </p>
                                                <div class="flex items-center gap-2 mt-1">
                                                    <span class="badge badge-xs badge-outline">
                                                        {question.data.question_type || "unknown"}
                                                    </span>
                                                    {#if question.data.difficulty}
                                                        <span class="badge badge-xs badge-secondary">
                                                            Level {question.data.difficulty}
                                                        </span>
                                                    {/if}
                                                </div>
                                            </div>

                                            {#if isSelected}
                                                <CheckIcon class="h-4 w-4 text-success" />
                                            {/if}
                                        </div>
                                    {/each}
                                </div>

                                <!-- Pagination -->
                                {#if questions.total_pages > 1}
                                    <div class="p-4 border-t border-base-300">
                                        <div class="flex items-center justify-between">
                                            <span class="text-sm text-base-content/60">
                                                Page {questions.page_number} of {questions.total_pages}
                                                ({questions.total_items} total)
                                            </span>
                                            <div class="join">
                                                <Button
                                                    variant="outline"
                                                    size="xs"
                                                    disabled={questions.page_number <= 1}
                                                    onclick={() => handleAddQuestionsPageChange(questions.page_number - 1)}
                                                    class="join-item"
                                                >
                                                    Prev
                                                </Button>
                                                <Button
                                                    variant="outline"
                                                    size="xs"
                                                    disabled={questions.page_number >= questions.total_pages}
                                                    onclick={() => handleAddQuestionsPageChange(questions.page_number + 1)}
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
                    </div>
                {/if}
            </div>
        </div>
    {/if}

    <!-- Questions Container with improved styling and scroll detection -->
    <div
        bind:this={questionsContainer}
        onscroll={handleScroll}
        class="h-[70vh] overflow-y-auto p-3 md:mx-4 lg:mx-8 space-y-3 scroll-smooth pb-64 bg-primary/3 rounded-lg shadow-2xl ring-1 ring-base-300/50 backdrop-blur-sm"
    >
        <div class="max-w-4xl mx-auto">
            {#if filteredQuestions.length === 0}
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
                                d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                            />
                        </svg>
                    </div>
                    <h3 class="text-xl font-semibold text-base-content mb-2">
                        No questions found
                    </h3>
                    <p class="text-base-content/60">
                        Try adjusting your search or filter criteria.
                    </p>
                </div>
            {:else}
                {#each filteredQuestions as question, index (question.id)}
                    {@const userAnswer = questionSet?.answers?.find(
                        (a) => a.question_id === question.id,
                    )}
                    <div class="mb-8">
                        <QuestionRenderer
                            {question}
                            questionNumber={index + 1}
                            isActive={index === currentQuestionIndex}
                            {userAnswer}
                            {live}
                            {userQuestionSets}
                        />
                    </div>
                {/each}
            {/if}
        </div>
    </div>
</div>
