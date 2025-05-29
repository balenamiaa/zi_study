<script>
    import { onMount } from "svelte";
    import Button from "./Button.svelte";
    import Modal from "./Modal.svelte";
    import Alert from "./Alert.svelte";
    import TextInput from "./TextInput.svelte";

    let {
        live,
        isOpen = false,
        onClose,
        initialImageUrl = null,
        children,
    } = $props();

    let activeMethod = $state("file-system");
    let imageUrl = $state("");
    let imagePreview = $state(initialImageUrl);
    let dragActive = $state(false);
    let isFocused = $state(false);
    let uploadLoading = $state(false); // Mostly for url or clipboard upload methods
    let uploadError = $state(null); // Mostly for url or clipboard upload methods

    $effect(() => {
        if (isOpen) {
            imagePreview = initialImageUrl;
            imageUrl = "";
            uploadError = null;
            uploadLoading = false;
        }
    });

    function handleUrlChange(url) {
        imageUrl = url;
        if (!url || url.trim() === "") {
            imagePreview = null;
        } else {
            imagePreview = url;
        }
    }

    async function handleUrlSubmit() {
        if (!imageUrl || imageUrl.trim() === "") return;

        uploadLoading = true;
        uploadError = null;

        try {
            const response = await fetch(imageUrl);

            if (!response.ok) {
                let errorBodyMessage = "";
                try {
                    const errorBody = await response.text();
                    if (errorBody) {
                        errorBodyMessage = ` - Server responded with: ${errorBody.substring(0, 100)}${errorBody.length > 100 ? "..." : ""}`;
                    }
                } catch (e) {}
                throw new Error(
                    `Failed to fetch image: ${response.status} ${response.statusText}${errorBodyMessage}`,
                );
            }

            const blob = await response.blob();
            const contentType =
                response.headers.get("Content-Type") ||
                blob.type ||
                "application/octet-stream";

            let filename;
            try {
                const urlObj = new URL(imageUrl);
                const pathname = urlObj.pathname;
                const lastSegment = decodeURIComponent(
                    pathname.substring(pathname.lastIndexOf("/") + 1),
                );

                if (
                    lastSegment &&
                    lastSegment.includes(".") &&
                    lastSegment.trim() !== "."
                ) {
                    filename = lastSegment;
                }
            } catch (e) {
                console.warn(
                    "Could not parse filename from URL, will use a generic one:",
                    imageUrl,
                    e,
                );
            }

            if (!filename) {
                const typeParts = contentType.split("/");
                let extension =
                    typeParts.length > 1
                        ? typeParts[1]
                              .toLowerCase()
                              .split(";")[0]
                              .replace("+xml", "xml")
                        : "dat";
                filename = `image_from_url.${extension}`;
            }

            const file = new File([blob], filename, { type: contentType });
            const url = URL.createObjectURL(file);
            imagePreview = url;

            const dt = new DataTransfer();
            dt.items.add(file);

            live.upload("profile_picture", dt.items);
        } catch (error) {
            console.error("Error processing image from URL:", error);
            uploadError =
                error.message ||
                "An unexpected error occurred while processing the image URL.";
            uploadLoading = false;
        }
    }

    function handlePaste(event) {
        const items = event.clipboardData.items;
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            if (item && item.type.startsWith("image")) {
                const file = item.getAsFile();
                const url = URL.createObjectURL(file);
                imagePreview = url;
                uploadLoading = true;

                const dt = new DataTransfer();
                dt.items.add(file);

                live.upload("profile_picture", dt.items);
            }
        }
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

        const file = event.dataTransfer.files[0];
        if (file) {
            const url = URL.createObjectURL(file);
            imagePreview = url;
            uploadLoading = true;

            const dt = new DataTransfer();
            dt.items.add(file);

            live.upload("profile_picture", dt.items);
        }
    }

    onMount(() => {});
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
                    ondragenter.prevent={(e) => handleDrag(e, true)}
                    ondragover.prevent={(e) => handleDrag(e, true)}
                    ondragleave.prevent={(e) => handleDrag(e, false)}
                    ondrop.prevent={handleDrop}
                    onfocus={() => (isFocused = true)}
                    onblur={() => (isFocused = false)}
                    aria-disabled={uploadLoading}
                    aria-label="Upload image from file system"
                >
                    {#if children}
                        {@render children()}
                    {/if}
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
                        or click to browse files
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
                    onInput={(e) => handleUrlChange(e.target.value)}
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
