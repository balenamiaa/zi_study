<script>
    import { onMount } from "svelte";
    import Button from "./Button.svelte";
    import Modal from "./Modal.svelte";
    import Alert from "./Alert.svelte";
    import TextInput from "./TextInput.svelte";

    const CHUNK_SIZE = 100 * 1024; // 100KB

    let {
        live,
        isOpen = false,
        onClose,
        imagePreviewUrl = null,
        children,
    } = $props();

    let activeMethod = $state("file-system");
    let imageUrl = $state("");
    let imagePreview = $state(imagePreviewUrl);
    let dragActive = $state(false);
    let isFocused = $state(false);
    let uploadLoading = $state(false);
    let uploadError = $state(null);
    let fileInput = $state(null);

    $effect(() => {
        if (isOpen) {
            imagePreview = imagePreviewUrl;
            imageUrl = "";
            uploadError = null;
            uploadLoading = false;
        }
    });

    onMount(() => {
        live.handleEvent("upload_success", ({ preview_url }) => {
            // imagePreview = preview_url;
            // Not really needed because imagePreviewUrl will bet set from the backend which will update here.
        });
    });

    async function handleUrlSubmit() {
        if (!imageUrl || imageUrl.trim() === "") return;

        uploadLoading = true;
        uploadError = null;

        live.pushEvent("upload_from_url", { url: imageUrl });
    }

    async function handleFileUpload(file) {
        try {
            uploadLoading = true;

            live.pushEvent("upload_file_chunked", {
                state: "start",
                file_name: file.name,
                file_size: file.size,
                file_type: file.type,
            });

            let offset = 0;
            let chunkIndex = 0;

            while (offset < file.size) {
                const chunkBlob = file.slice(
                    offset,
                    Math.min(offset + CHUNK_SIZE, file.size),
                );

                const chunkArrayBuffer = await chunkBlob.arrayBuffer();

                live.pushEvent("upload_file_chunked", {
                    state: "chunk",
                    file_name: file.name,
                    chunk_index: chunkIndex,
                    chunk_data: chunkArrayBuffer,
                    chunk_size: chunkArrayBuffer.byteLength,
                });

                offset += chunkArrayBuffer.byteLength;
                chunkIndex++;
            }

            live.pushEvent("upload_file_chunked", {
                state: "end",
                file_name: file.name,
            });
        } catch (error) {
            uploadError =
                "Error uploading pasted image: " +
                (error.message || "Unknown error");
            live.pushEvent("upload_file_chunked", {
                state: "error",
                file_name: file ? file.name : "unknown_file",
                error_message: error.message || "Unknown error during chunking",
            });
        } finally {
            uploadLoading = false;
        }
    }

    async function handlePaste(event) {
        uploadError = "";

        const items = event.clipboardData.items;

        if (!items || items.length === 0) {
            uploadError = "No items found in clipboard.";
            uploadLoading = false;
            return;
        }

        if (items.length > 1) {
            uploadError = "Multiple items pasted. Please paste only one image.";
            uploadLoading = false;
            return;
        }

        const firstItem = items[0];
        if (!firstItem || !firstItem.type.startsWith("image")) {
            uploadError =
                "Pasted item is not an image. Found type: " +
                (firstItem ? firstItem.type : "unknown");
            uploadLoading = false;
            return;
        }

        const file = firstItem.getAsFile();
        if (!file) {
            uploadError = "Could not retrieve file from pasted item.";
            uploadLoading = false;
            return;
        }

        handleFileUpload(file);
    }

    function handleDrag(event, active) {
        event.preventDefault();
        event.stopPropagation();
        dragActive = active;
    }

    function handleDrop(event) {
        event.preventDefault();
        event.stopPropagation();
        dragActive = false;

        const files = event.dataTransfer.files;
        if (files.length > 1) {
            uploadError = "Multiple files dropped. Please drop only one image.";
            uploadLoading = false;
            return;
        }

        const file = files[0];
        if (!file || !file.type.startsWith("image")) {
            uploadError = "Dropped item is not an image.";
            uploadLoading = false;
            return;
        }

        handleFileUpload(file);
    }

    function handleFileInputChange(event) {
        const inputElement = event.target;
        const files = inputElement.files;

        if (files.length > 1) {
            uploadError =
                "Multiple files selected. Please select only one image.";
            uploadLoading = false;
            return;
        }

        const file = files[0];
        if (!file || !file.type.startsWith("image")) {
            uploadError = "Selected item is not an image.";
            uploadLoading = false;
            return;
        }

        handleFileUpload(file);

        inputElement.value = null;
    }

    function triggerFileInputClick() {
        if (fileInput) {
            fileInput.click();
        }
    }
</script>

<Modal
    {isOpen}
    {onClose}
    title="Upload Profile Image"
    size="md"
    closeOnOverlayClick={!uploadLoading}
    showCloseButton={!uploadLoading}
>
    {#if uploadError}
        <Alert
            variant="error"
            dismissible={true}
            onDismiss={() => (uploadError = null)}
            class="mb-4"
        >
            {uploadError}
        </Alert>
    {/if}

    <div class="mb-6 flex justify-center">
        <div class="relative w-32 h-32">
            {#if imagePreview}
                <img
                    class="w-32 h-32 rounded-full object-cover border-2 border-base-300"
                    src={imagePreview}
                    alt="Profile preview"
                />
            {:else}
                <div
                    class="w-32 h-32 rounded-full bg-base-200 flex items-center justify-center relative overflow-hidden"
                >
                    <svg
                        class="w-10 h-10 text-base-content/50"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
                        />
                    </svg>
                </div>
            {/if}

            {#if uploadLoading}
                <div
                    class="absolute inset-0 flex items-center justify-center bg-black/60 rounded-full"
                >
                    <div
                        class="loading loading-spinner loading-md text-white"
                    ></div>
                </div>
            {/if}
        </div>
    </div>

    <div class="flex mb-4 border-b border-base-300">
        <button
            class="flex items-center px-4 py-2 text-sm font-medium border-b-2 transition-colors
                   {activeMethod === 'file-system'
                ? 'border-primary text-primary'
                : 'border-transparent text-base-content/70 hover:text-primary'}
                   {uploadLoading ? 'opacity-50 cursor-not-allowed' : ''}"
            onclick={() => (activeMethod = "file-system")}
            disabled={uploadLoading}
        >
            <svg
                class="w-4 h-4 mr-2"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
            >
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
                />
            </svg>
            Upload
        </button>

        <button
            class="flex items-center px-4 py-2 text-sm font-medium border-b-2 transition-colors
                   {activeMethod === 'url'
                ? 'border-primary text-primary'
                : 'border-transparent text-base-content/70 hover:text-primary'}
                   {uploadLoading ? 'opacity-50 cursor-not-allowed' : ''}"
            onclick={() => (activeMethod = "url")}
            disabled={uploadLoading}
        >
            <svg
                class="w-4 h-4 mr-2"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
            >
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"
                />
            </svg>
            URL
        </button>

        <button
            class="flex items-center px-4 py-2 text-sm font-medium border-b-2 transition-colors
                   {activeMethod === 'paste'
                ? 'border-primary text-primary'
                : 'border-transparent text-base-content/70 hover:text-primary'}
                   {uploadLoading ? 'opacity-50 cursor-not-allowed' : ''}"
            onclick={() => (activeMethod = "paste")}
            disabled={uploadLoading}
        >
            <svg
                class="w-4 h-4 mr-2"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
            >
                <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                />
            </svg>
            Paste
        </button>
    </div>

    <div>
        <input
            type="file"
            accept="image/*"
            bind:this={fileInput}
            onchange={handleFileInputChange}
            class="hidden"
        />

        {#if activeMethod === "file-system"}
            <div class="mt-4">
                <div
                    class="relative border-2 border-dashed rounded-lg p-6 text-center transition-all duration-300 overflow-hidden cursor-pointer
                           {dragActive
                        ? 'border-primary bg-primary/10 shadow-md scale-[1.02]'
                        : isFocused
                          ? 'border-primary ring-2 ring-primary/20'
                          : 'border-base-300'}
                           {uploadLoading
                        ? 'opacity-50 cursor-not-allowed'
                        : ''}
                           hover:border-primary/60 hover:shadow-md hover:bg-primary/5 hover:scale-[1.01] active:scale-100"
                    onclick={triggerFileInputClick}
                    onkeydown={(e) => {
                        if (e.key === "Enter" || e.key === " ")
                            triggerFileInputClick();
                    }}
                    role="button"
                    tabindex="0"
                    ondragenter.prevent={(e) => handleDrag(e, true)}
                    ondragover.prevent={(e) => handleDrag(e, true)}
                    ondragleave.prevent={(e) => handleDrag(e, false)}
                    ondrop.prevent={handleDrop}
                    onfocus={() => (isFocused = true)}
                    onblur={() => (isFocused = false)}
                    aria-disabled={uploadLoading}
                    aria-label="Upload image from file system"
                >
                    <div style="display: none;">
                        {#if children}
                            {@render children()}
                        {/if}
                    </div>
                    <svg
                        class="w-8 h-8 mx-auto mb-2 text-base-content/50"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
                        />
                    </svg>
                    <p class="mb-1">Drag and drop your image here</p>
                    <p class="text-sm text-base-content/70">
                        or <span class="font-semibold text-primary"
                            >click to browse files</span
                        >
                    </p>
                </div>
            </div>
        {:else if activeMethod === "url"}
            <div class="mt-4">
                <TextInput
                    type="text"
                    label="Image URL"
                    placeholder="https://example.com/image.jpg"
                    value={imageUrl}
                    helperText="Enter the URL of an image"
                    disabled={uploadLoading}
                    class="mb-4"
                />

                <Button
                    variant="primary"
                    size="md"
                    fullWidth={true}
                    disabled={uploadLoading ||
                        !imageUrl ||
                        imageUrl.trim() === ""}
                    loading={uploadLoading}
                    onClick={handleUrlSubmit}
                >
                    {uploadLoading ? "Uploading..." : "Use this image"}
                </Button>
            </div>
        {:else if activeMethod === "paste"}
            <div class="mt-4">
                <div
                    class="relative border-2 border-dashed rounded-lg p-6 text-center transition-all duration-300 overflow-hidden cursor-pointer
                           {isFocused
                        ? 'border-primary ring-2 ring-primary/20'
                        : 'border-base-300'}
                           {uploadLoading
                        ? 'opacity-50 cursor-not-allowed'
                        : ''}
                           hover:border-primary/60 hover:shadow-md hover:bg-primary/5 hover:scale-[1.01] active:scale-100"
                    tabindex={uploadLoading ? -1 : 0}
                    onfocus={() => (isFocused = true)}
                    onblur={() => (isFocused = false)}
                    onpaste={handlePaste}
                    onclick={uploadLoading
                        ? null
                        : (e) => e.currentTarget.focus()}
                    onkeydown={(e) =>
                        e.key === "Enter" && e.currentTarget.focus()}
                    role="button"
                    aria-disabled={uploadLoading}
                    aria-label="Paste image from clipboard"
                >
                    <svg
                        class="w-8 h-8 mx-auto mb-3 text-primary"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                        />
                    </svg>
                    <p class="mb-2 font-medium text-base-content">
                        Click here and paste your image
                        <span
                            class="inline-block px-2 py-0.5 bg-primary/10 rounded text-sm text-primary font-mono"
                        >
                            Ctrl+V
                        </span>
                    </p>
                    <p class="text-sm text-base-content/70 leading-relaxed">
                        You can paste from clipboard or screenshot
                    </p>
                </div>
            </div>
        {/if}
    </div>
</Modal>
