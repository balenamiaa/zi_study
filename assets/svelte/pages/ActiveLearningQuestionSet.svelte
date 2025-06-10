<script>
    import {
        SearchIcon,
        PlusIcon,
        XIcon,
        CheckIcon,
        PencilIcon,
    } from "lucide-svelte";
    import VirtualList from "../components/VirtualList.svelte";
    import FilterPanel from "../components/questions/FilterPanel.svelte";
    import QuestionsOverview from "../components/questions/QuestionsOverview.svelte";
    import QuestionRenderer from "../components/questions/QuestionRenderer.svelte";
    import TagsManagementModal from "../components/questions/TagsManagementModal.svelte";
    import TextInput from "../components/TextInput.svelte";

    let {
        live,
        questionSetMeta,
        initialQuestions,
        initialAnswers,
        streamingState,
        currentUser,
        userQuestionSets,
    } = $props();

    // Core state
    let allQuestions = $state([...initialQuestions]);
    let allAnswers = $state([...initialAnswers]);
    let currentStreamingState = $state({ ...streamingState });

    // UI state
    let searchQuery = $state("");
    let showFilters = $state(false);
    let difficultyRange = $state([1, 5]);
    let answerStatus = $state("all");
    let currentQuestionIndex = $state(0);
    let showTagsModal = $state(false);
    let isEditingHeader = $state(false);
    let editingValues = $state({
        title: "",
        description: "",
        is_private: false,
    });
    let isDraggingSlider = $state(false);

    let questionsContainer = $state();
    let virtualList = $state();
    let loadingTrigger = $state();
    let questionObserver = $state();
    let intersectionObserver = $state();

    let answerLookup = $derived(
        new Map(allAnswers.map((answer) => [answer.question_id, answer])),
    );

    let questionSet = $derived({
        ...questionSetMeta,
        questions: allQuestions,
        answers: allAnswers,
    });

    let filteredQuestions = $derived.by(() => {
        if (!allQuestions || allQuestions.length === 0) return [];

        const searchLower = searchQuery.toLowerCase();

        return allQuestions.filter((question) => {
            const matchesSearch =
                searchQuery === "" ||
                question.data.question_text
                    ?.toLowerCase()
                    .includes(searchLower);

            const difficulty = parseInt(question.data.difficulty) || 3;
            const matchesDifficulty =
                difficulty >= difficultyRange[0] &&
                difficulty <= difficultyRange[1];

            const matchesAnswerStatus =
                answerStatus === "all" || answerStatus === "unanswered";

            return matchesSearch && matchesDifficulty && matchesAnswerStatus;
        });
    });

    let virtualListItems = $derived.by(() => {
        const items = [...filteredQuestions];
        if (currentStreamingState?.has_more) {
            items.push({ isLoadingTrigger: true });
        }
        return items;
    });

    function setupQuestionObserver() {
        if (!questionsContainer || questionObserver) return;

        questionObserver = new IntersectionObserver(
            (entries) => {
                if (isDraggingSlider) return;

                let maxRatio = 0;
                let mostVisibleIndex = currentQuestionIndex;

                entries.forEach((entry) => {
                    if (
                        entry.isIntersecting &&
                        entry.intersectionRatio > maxRatio
                    ) {
                        const index = parseInt(entry.target.dataset.index);
                        if (!isNaN(index)) {
                            maxRatio = entry.intersectionRatio;
                            mostVisibleIndex = index;
                        }
                    }
                });

                if (
                    mostVisibleIndex !== currentQuestionIndex &&
                    maxRatio > 0.3
                ) {
                    currentQuestionIndex = mostVisibleIndex;
                }
            },
            {
                root: questionsContainer,
                rootMargin: "-20% 0px -20% 0px",
                threshold: [0, 0.1, 0.3, 0.5, 0.7, 0.9],
            },
        );
    }

    function observeQuestion(element, index) {
        if (!element) return { destroy: () => {} };

        element.dataset.index = index.toString();

        if (questionObserver) {
            questionObserver.observe(element);
        }

        return {
            destroy() {
                if (questionObserver && element) {
                    questionObserver.unobserve(element);
                }
            },
        };
    }

    $effect(() => {
        if (questionsContainer && !questionObserver) {
            setupQuestionObserver();
        }

        return () => {
            if (questionObserver) {
                questionObserver.disconnect();
                questionObserver = null;
            }
        };
    });

    $effect(() => {
        filteredQuestions; // Track

        if (questionObserver && questionsContainer) {
            const questionElements =
                questionsContainer.querySelectorAll("[data-index]");
            questionElements.forEach((element) => {
                questionObserver.observe(element);
            });
        }
    });

    $effect(() => {
        if (loadingTrigger && !intersectionObserver && questionsContainer) {
            intersectionObserver = new IntersectionObserver(
                (entries) => {
                    entries.forEach((entry) => {
                        if (
                            entry.isIntersecting &&
                            currentStreamingState?.has_more &&
                            !currentStreamingState?.is_streaming
                        ) {
                            live.pushEvent("request_more_questions", {});
                        }
                    });
                },
                {
                    root: questionsContainer,
                    rootMargin: "200px",
                    threshold: 0.1,
                },
            );
            intersectionObserver.observe(loadingTrigger);
        }

        return () => {
            if (intersectionObserver) {
                intersectionObserver.disconnect();
                intersectionObserver = null;
            }
        };
    });

    $effect(() => {
        if (!live) return;

        if (
            currentStreamingState.has_more &&
            !currentStreamingState.is_streaming
        ) {
            live.pushEvent("start_streaming", {});
        }

        const handleQuestionsChunk = live.handleEvent(
            "questions_chunk_received",
            (event) => {
                allQuestions = [...allQuestions, ...event.questions];
                allAnswers = [...allAnswers, ...event.answers];
                currentStreamingState = event.streaming_state;
            },
        );

        const handleAnswerUpdated = live.handleEvent(
            "answer_updated",
            (event) => {
                const existingIndex = allAnswers.findIndex(
                    (a) => a.question_id === event.answer.question_id,
                );
                if (existingIndex >= 0) {
                    allAnswers[existingIndex] = event.answer;
                } else {
                    allAnswers = [...allAnswers, event.answer];
                }
                allAnswers = [...allAnswers];
            },
        );

        const handleAnswerReset = live.handleEvent("answer_reset", (event) => {
            allAnswers = allAnswers.filter(
                (a) => a.question_id !== event.question_id,
            );
        });

        const handleMetaUpdated = live.handleEvent(
            "question_set_meta_updated",
            (event) => {
                questionSetMeta[event.field] = event.value;
            },
        );

        return () => {
            live.removeHandleEvent(handleQuestionsChunk);
            live.removeHandleEvent(handleAnswerUpdated);
            live.removeHandleEvent(handleAnswerReset);
            live.removeHandleEvent(handleMetaUpdated);
        };
    });

    // UI event handlers
    function loadMoreQuestions() {
        if (
            live &&
            currentStreamingState?.has_more &&
            !currentStreamingState?.is_streaming
        ) {
            live.pushEvent("request_more_questions", {});
        }
    }

    function handleSliderChange(index) {
        isDraggingSlider = true;
        currentQuestionIndex = index;
        scrollToQuestion(index);
        setTimeout(() => {
            isDraggingSlider = false;
        }, 500);
    }

    function scrollToQuestion(index) {
        if (virtualList && filteredQuestions[index]) {
            virtualList.scrollToIndex(index, { behavior: "smooth" });
        }
    }

    function handleFieldUpdate(field, value) {
        live.pushEvent("update_question_set", { field, value });
    }

    function startHeaderEdit() {
        if (
            !questionSet?.owner ||
            questionSet.owner.email !== currentUser?.email
        )
            return;
        editingValues = {
            title: questionSet.title || "",
            description: questionSet.description || "",
            is_private: questionSet.is_private || false,
        };
        isEditingHeader = true;
    }

    function cancelHeaderEdit() {
        isEditingHeader = false;
    }

    function saveHeaderChanges() {
        if (editingValues.title !== questionSet.title) {
            handleFieldUpdate("title", editingValues.title);
        }
        if (editingValues.description !== questionSet.description) {
            handleFieldUpdate("description", editingValues.description);
        }
        if (editingValues.is_private !== questionSet.is_private) {
            handleFieldUpdate("is_private", editingValues.is_private);
        }
        isEditingHeader = false;
    }
</script>

<div class="min-h-screen bg-base-100 flex flex-col gap-4">
    <div class="bg-base-200 border-b border-base-300">
        <div class="max-w-8xl mx-auto p-2 md:p-4">
            {#if isEditingHeader}
                <!-- Edit Mode -->
                <div
                    class="bg-base-100 rounded-lg p-4 border border-base-300 space-y-4"
                >
                    <div
                        class="flex flex-col sm:flex-row sm:items-center justify-between gap-3"
                    >
                        <h3 class="text-lg font-semibold text-base-content">
                            Edit Question Set
                        </h3>
                        <div class="flex items-center gap-2">
                            <button
                                class="btn btn-ghost btn-sm gap-2"
                                onclick={cancelHeaderEdit}
                            >
                                <XIcon class="h-4 w-4" />
                                Cancel
                            </button>
                            <button
                                class="btn btn-primary btn-sm gap-2"
                                onclick={saveHeaderChanges}
                            >
                                <CheckIcon class="h-4 w-4" />
                                Save Changes
                            </button>
                        </div>
                    </div>

                    <div class="space-y-4">
                        <!-- Title -->
                        <div>
                            <label
                                for="title"
                                class="block text-sm font-medium text-base-content mb-2"
                                >Title</label
                            >
                            <input
                                type="text"
                                bind:value={editingValues.title}
                                placeholder="Question Set Title"
                                class="input input-bordered w-full text-2xl font-bold"
                            />
                        </div>

                        <!-- Description -->
                        <div>
                            <label
                                for="description"
                                class="block text-sm font-medium text-base-content mb-2"
                                >Description</label
                            >
                            <textarea
                                bind:value={editingValues.description}
                                placeholder="Add a description..."
                                class="textarea textarea-bordered w-full"
                                rows="3"
                            ></textarea>
                        </div>

                        <!-- Privacy Toggle -->
                        <div>
                            <label
                                for="is_private"
                                class="block text-sm font-medium text-base-content mb-2"
                                >Visibility</label
                            >
                            <div class="form-control">
                                <label
                                    class="cursor-pointer label justify-start gap-3"
                                >
                                    <input
                                        type="checkbox"
                                        bind:checked={editingValues.is_private}
                                        class="toggle toggle-primary"
                                    />
                                    <span class="label-text font-medium">
                                        {editingValues.is_private
                                            ? "Private Set"
                                            : "Public Set"}
                                    </span>
                                </label>
                            </div>
                        </div>
                    </div>
                </div>
            {:else}
                <!-- Display Mode -->
                <div class="space-y-4 relative">
                    <!-- Edit button positioned absolutely in top right -->
                    {#if questionSet?.owner && questionSet.owner.email === currentUser?.email}
                        <button
                            class="btn btn-outline btn-xs gap-1 absolute top-0 right-0 z-10"
                            onclick={startHeaderEdit}
                        >
                            <PencilIcon class="h-3 w-3" />
                            <span class="hidden sm:inline">Edit</span>
                        </button>
                    {/if}

                    <div class="pr-16 sm:pr-20">
                        <div class="mb-3">
                            <h1
                                class="text-2xl sm:text-3xl font-bold text-base-content break-words"
                            >
                                {questionSet.title || "Untitled Question Set"}
                            </h1>
                        </div>

                        <!-- Owner and metadata info -->
                        <div
                            class="flex flex-col sm:flex-row sm:items-center gap-3 sm:gap-4 mb-3"
                        >
                            {#if questionSet?.owner}
                                <div class="flex items-center gap-2">
                                    <div
                                        class="w-6 h-6 bg-gradient-to-br from-primary to-secondary rounded-full flex items-center justify-center"
                                    >
                                        <span
                                            class="text-xs font-bold text-primary-content"
                                        >
                                            {questionSet.owner.email
                                                .charAt(0)
                                                .toUpperCase()}
                                        </span>
                                    </div>
                                    <span
                                        class="text-sm text-base-content/70 font-medium"
                                    >
                                        by {questionSet.owner.email}
                                    </span>
                                </div>
                            {/if}

                            <div class="flex items-center gap-2">
                                <div
                                    class="badge badge-sm {questionSet.is_private
                                        ? 'badge-secondary'
                                        : 'badge-primary'} font-medium"
                                >
                                    {questionSet.is_private
                                        ? "Private"
                                        : "Public"}
                                </div>
                            </div>
                        </div>

                        {#if questionSet.description}
                            <div
                                class="text-base-content/70 text-sm sm:text-base break-words"
                            >
                                {questionSet.description}
                            </div>
                        {:else}
                            <div class="text-base-content/50 italic text-sm">
                                No description provided
                            </div>
                        {/if}
                    </div>

                    <!-- Tags section -->
                    <div class="flex items-center gap-2 flex-wrap">
                        {#if questionSet?.tags && questionSet.tags.length > 0}
                            {#each questionSet.tags as tag}
                                <span class="badge badge-outline text-xs"
                                    >{tag.name}</span
                                >
                            {/each}
                        {:else}
                            <span class="text-base-content/50 text-sm"
                                >No tags</span
                            >
                        {/if}

                        {#if questionSet?.owner && questionSet.owner.email === currentUser?.email}
                            <button
                                class="btn btn-ghost btn-circle btn-xs hover:bg-primary hover:text-primary-content transition-colors"
                                onclick={() => (showTagsModal = true)}
                                title="Manage tags"
                            >
                                <PlusIcon class="h-3 w-3" />
                            </button>
                        {/if}
                    </div>
                </div>
            {/if}
        </div>
    </div>

    <div class="bg-base-100 border-b border-base-300">
        <div class="max-w-8xl mx-auto p-2 md:p-4">
            <div
                class="flex flex-col lg:flex-row gap-4 items-start lg:items-center"
            >
                <!-- Enhanced Search Input -->
                <div class="flex-1 w-full lg:max-w-lg">
                    <TextInput
                        bind:value={searchQuery}
                        placeholder="Search questions..."
                        fullWidth={true}
                        size="lg"
                        variant="bordered"
                        icon={SearchIcon}
                        type="search"
                    />
                </div>

                <!-- Filters and Results Row -->
                <div
                    class="flex flex-col sm:flex-row items-start sm:items-center gap-4 w-full lg:w-auto"
                >
                    <button
                        class="btn btn-outline gap-2 w-full sm:w-auto"
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
                        Filters
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
                        {filteredQuestions.length} of {currentStreamingState?.total_count ||
                            questionSet?.questions?.length ||
                            0} questions
                        {#if currentStreamingState?.loaded_count && currentStreamingState.loaded_count < currentStreamingState.total_count}
                            <span class="text-primary"
                                >({currentStreamingState.loaded_count} loaded)</span
                            >
                        {/if}
                    </div>
                </div>
            </div>

            {#if showFilters}
                <div
                    class="mt-4 bg-base-200 rounded-lg p-4 border border-base-300"
                >
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
            loadingState={currentStreamingState}
        />
    {/if}

    <div
        bind:this={questionsContainer}
        class="h-[70vh] p-3 md:mx-2 lg:mx-4 bg-primary/3 rounded-lg shadow-2xl ring-1 ring-base-300/50 backdrop-blur-sm"
    >
        <div class="max-w-8xl mx-auto h-full">
            {#if filteredQuestions.length === 0 && !currentStreamingState?.is_streaming}
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
                <VirtualList
                    bind:this={virtualList}
                    items={virtualListItems}
                    estimatedItemHeight={350}
                    height="100%"
                >
                    {#snippet children(item, index)}
                        {#if item.isLoadingTrigger}
                            <!-- Loading trigger element -->
                            <div bind:this={loadingTrigger} class="w-full py-8">
                                {#if currentStreamingState?.is_streaming}
                                    <div class="text-center">
                                        <div
                                            class="loading loading-spinner loading-lg text-primary"
                                        ></div>
                                        <p class="text-base-content/60 mt-4">
                                            Streaming in progress...
                                        </p>
                                    </div>
                                {:else}
                                    <div class="text-center">
                                        <button
                                            class="btn btn-outline btn-lg gap-2"
                                            onclick={loadMoreQuestions}
                                        >
                                            <svg
                                                class="w-5 h-5"
                                                fill="none"
                                                stroke="currentColor"
                                                viewBox="0 0 24 24"
                                            >
                                                <path
                                                    stroke-linecap="round"
                                                    stroke-linejoin="round"
                                                    stroke-width="2"
                                                    d="M19 14l-7 7m0 0l-7-7m7 7V3"
                                                ></path>
                                            </svg>
                                            Load More Questions
                                        </button>
                                    </div>
                                {/if}
                            </div>
                        {:else}
                            {@const question = item}
                            {@const userAnswer = answerLookup.get(question.id)}
                            <div class="p-3" use:observeQuestion={index}>
                                <QuestionRenderer
                                    {question}
                                    questionNumber={index + 1}
                                    isActive={index === currentQuestionIndex}
                                    {userAnswer}
                                    {live}
                                    {userQuestionSets}
                                />
                            </div>
                        {/if}
                    {/snippet}
                </VirtualList>
            {/if}
        </div>
    </div>
</div>

<TagsManagementModal
    isOpen={showTagsModal}
    onClose={() => (showTagsModal = false)}
    questionSetId={questionSet?.id}
    currentTags={questionSet?.tags || []}
    {live}
/>
