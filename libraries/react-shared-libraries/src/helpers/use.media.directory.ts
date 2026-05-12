import { useCallback } from 'react';

/**
 * Resolves media / static asset URLs for the browser. Stored paths may use an
 * old public host; nginx serves uploaded files at /uploads/... from UPLOAD_DIRECTORY.
 */
export function resolveMediaPublicUrl(path: string): string {
  if (!path) {
    return path;
  }

  if (typeof window === 'undefined') {
    return path;
  }

  try {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      const u = new URL(path);
      if (
        u.pathname.startsWith('/uploads/') &&
        u.origin !== window.location.origin
      ) {
        return `${window.location.origin}${u.pathname}${u.search}${u.hash}`;
      }
      return path;
    }

    if (path.startsWith('/uploads/') || path.startsWith('/icons/')) {
      return `${window.location.origin}${path}`;
    }
  } catch {
    return path;
  }

  return path;
}

export const useMediaDirectory = () => {
  const set = useCallback((path: string) => resolveMediaPublicUrl(path), []);

  return {
    set,
  };
};
