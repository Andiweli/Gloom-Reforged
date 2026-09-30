/* HTTPS/redirect handling adapted from the supplied AmiMAIL update.c. */
#include "release.h"
#include "tls.h"
#include "compat.h"
#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define T(id,en) (en)
#define AMG_UPDATE_HTTP_URL_MAX 2304U
#define AMG_UPDATE_HTTP_HOST_MAX 256U
#define AMG_UPDATE_HTTP_PATH_MAX 2048U
#define AMG_UPDATE_REDIRECT_MAX 5U
static int text_equal_nocase_n(const char *a,const char *b,size_t n)
{ size_t i; for(i=0;i<n;++i) if(!a[i]||!b[i]||tolower((unsigned char)a[i])!=tolower((unsigned char)b[i])) return 0; return 1; }
static const unsigned char *find_header_end(const unsigned char *data,
                                            size_t length)
{
    size_t i;
    if (!data) return NULL;
    for (i = 0; i + 3U < length; ++i) {
        if (data[i] == '\r' && data[i + 1U] == '\n' &&
            data[i + 2U] == '\r' && data[i + 3U] == '\n')
            return data + i + 4U;
    }
    return NULL;
}

static int header_value(const unsigned char *data, size_t header_length,
                        const char *name, char *output, size_t capacity)
{
    size_t name_length, position = 0U;
    if (!data || !name || !output || !capacity) return 0;
    output[0] = 0;
    name_length = strlen(name);
    while (position < header_length) {
        size_t line_end = position;
        size_t value_start, value_end, copy_length;
        while (line_end + 1U < header_length &&
               !(data[line_end] == '\r' && data[line_end + 1U] == '\n'))
            ++line_end;
        if (line_end == position) break;
        if (line_end > position + name_length &&
            data[position + name_length] == ':' &&
            text_equal_nocase_n((const char *)data + position,
                                name, name_length)) {
            value_start = position + name_length + 1U;
            while (value_start < line_end &&
                   (data[value_start] == ' ' || data[value_start] == '\t'))
                ++value_start;
            value_end = line_end;
            while (value_end > value_start &&
                   (data[value_end - 1U] == ' ' ||
                    data[value_end - 1U] == '\t'))
                --value_end;
            copy_length = value_end - value_start;
            if (copy_length >= capacity) return 0;
            memcpy(output, data + value_start, copy_length);
            output[copy_length] = 0;
            return 1;
        }
        if (line_end + 2U > header_length) break;
        position = line_end + 2U;
    }
    return 0;
}

static int string_contains_nocase(const char *text, const char *needle)
{
    size_t text_length, needle_length, i;
    if (!text || !needle) return 0;
    text_length = strlen(text);
    needle_length = strlen(needle);
    if (!needle_length || needle_length > text_length) return 0;
    for (i = 0; i + needle_length <= text_length; ++i) {
        if (text_equal_nocase_n(text + i, needle, needle_length)) return 1;
    }
    return 0;
}

static int decode_chunked_body(const unsigned char *data, size_t length,
                               AmgBuffer *output)
{
    size_t position = 0U;
    while (position < length) {
        char number[32], *endptr;
        size_t line_end = position, digits, chunk;
        while (line_end + 1U < length &&
               !(data[line_end] == '\r' && data[line_end + 1U] == '\n'))
            ++line_end;
        if (line_end + 1U >= length) return AMG_ERR_PARSE;
        digits = line_end - position;
        if (!digits || digits >= sizeof(number)) return AMG_ERR_PARSE;
        memcpy(number, data + position, digits);
        number[digits] = 0;
        if (!isxdigit((unsigned char)number[0])) return AMG_ERR_PARSE;
        errno = 0;
        chunk = strtoul(number, &endptr, 16);
        if (errno || endptr == number || (*endptr && *endptr != ';')) return AMG_ERR_PARSE;
        position = line_end + 2U;
        if (!chunk) {
            /* Require the final empty trailer line, even after a zero chunk. */
            while (position + 1U < length) {
                line_end = position;
                while (line_end + 1U < length &&
                       !(data[line_end] == '\r' && data[line_end+1U] == '\n')) ++line_end;
                if (line_end + 1U >= length) return AMG_ERR_PARSE;
                if (line_end == position) return AMG_OK;
                position = line_end + 2U;
            }
            return AMG_ERR_PARSE;
        }
        if (chunk > length - position) return AMG_ERR_PARSE;
        if (amg_buffer_append(output, data + position, chunk) != AMG_OK)
            return AMG_ERR_MEMORY;
        position += chunk;
        if (position + 2U > length || data[position] != '\r' ||
            data[position + 1U] != '\n')
            return AMG_ERR_PARSE;
        position += 2U;
    }
    return AMG_ERR_PARSE;
}

static int parse_https_url(const char *url,
                           char *host, size_t host_capacity,
                           char *path, size_t path_capacity)
{
    const char *start, *slash;
    size_t host_length;
    if (!url || strncmp(url, "https://", 8U) != 0 ||
        !host || !host_capacity || !path || path_capacity < 2U)
        return 0;
    { const unsigned char *p = (const unsigned char *)url;
      while (*p) { if (*p <= 32 || *p == 127 || *p == '\\') return 0; ++p; } }
    start = url + 8U;
    slash = strchr(start, '/');
    host_length = slash ? (size_t)(slash - start) : strlen(start);
    if (!host_length || host_length >= host_capacity ||
        (slash && strlen(slash) >= path_capacity))
        return 0;
    { size_t i; for (i=0;i<host_length;++i)
      if (!(isalnum((unsigned char)start[i]) || start[i]=='.' || start[i]=='-')) return 0; }
    memcpy(host, start, host_length);
    host[host_length] = 0;
    if (slash)
        strcpy(path, slash);
    else
        strcpy(path, "/");
    return 1;
}

static int resolve_redirect(const char *current_url, const char *location,
                            char *next_url, size_t capacity)
{
    char host[AMG_UPDATE_HTTP_HOST_MAX];
    char path[AMG_UPDATE_HTTP_PATH_MAX];
    int written;
    if (!current_url || !location || !*location || !next_url || !capacity)
        return 0;
    if (!strncmp(location, "https://", 8U)) {
        if (strlen(location) >= capacity) return 0;
        strcpy(next_url, location);
        return 1;
    }
    if (location[0] != '/' ||
        !parse_https_url(current_url, host, sizeof(host), path, sizeof(path)))
        return 0;
    written = snprintf(next_url, capacity, "https://%s%s", host, location);
    return written >= 0 && (size_t)written < capacity;
}

static int https_get_once(const char *url, size_t max_body,
                          AmgBuffer *body, int *status,
                          char *location, size_t location_capacity,
                          AmgError *error)
{
    char host[AMG_UPDATE_HTTP_HOST_MAX];
    char path[AMG_UPDATE_HTTP_PATH_MAX];
    char transfer_encoding[64];
    char content_length_text[32];
    AmgTlsConnection *connection = NULL;
    AmgBuffer request, response;
    unsigned char block[4096];
    const unsigned char *body_start;
    size_t header_length, raw_body_length;
    long count;
    int result = AMG_OK;

    if (!parse_https_url(url, host, sizeof(host), path, sizeof(path))) {
        amg_error_set(error, AMG_ERR_ARGUMENT,
                      T(MSG_INVALID_HTTPS_ADDRESS, "Invalid HTTPS address."));
        return AMG_ERR_ARGUMENT;
    }
    if (location && location_capacity) location[0] = 0;
    if (status) *status = 0;
    amg_buffer_init(&request);
    amg_buffer_init(&response);

    connection = amg_tls_connect(host, 443U, 30UL, error);
    if (!connection) {
        result = error && error->code ? error->code : AMG_ERR_TLS;
        goto done;
    }
    if (amg_buffer_append_cstr(&request, "GET ") != AMG_OK ||
        amg_buffer_append_cstr(&request, path) != AMG_OK ||
        amg_buffer_append_cstr(&request, " HTTP/1.1\r\nHost: ") != AMG_OK ||
        amg_buffer_append_cstr(&request, host) != AMG_OK ||
        amg_buffer_append_cstr(&request,
            "\r\nUser-Agent: GloomUpdate/" AMIGMAIL_VERSION ""
            "\r\nAccept: application/vnd.github+json, application/octet-stream"
            "\r\nConnection: close\r\n\r\n") != AMG_OK) {
        result = AMG_ERR_MEMORY;
        amg_error_set(error, result, T(MSG_NOT_ENOUGH_MEMORY, "Not enough memory."));
        goto done;
    }
    result = amg_tls_write_all(connection, request.data, request.length, error);
    if (result != AMG_OK) goto done;

    while (response.length <= max_body + 65536U) {
        count = amg_tls_read(connection, block, sizeof(block), error);
        if (count < 0) { result = AMG_ERR_IO; goto done; }
        if (count == 0) break;
        result = amg_buffer_append(&response, block, (size_t)count);
        if (result != AMG_OK) {
            amg_error_set(error, result,
                          T(MSG_NOT_ENOUGH_MEMORY, "Not enough memory."));
            goto done;
        }
    }
    if (response.length > max_body + 65536U) {
        result = AMG_ERR_LIMIT;
        amg_error_set(error, result,
                      T(MSG_HTTPS_RESPONSE_IS_TOO_LARGE, "HTTPS response is too large."));
        goto done;
    }
    if (amg_buffer_terminate(&response) != AMG_OK) {
        result = AMG_ERR_MEMORY;
        goto done;
    }
    if (sscanf((const char *)response.data, "HTTP/%*u.%*u %d", status) != 1) {
        result = AMG_ERR_PROTOCOL;
        amg_error_set(error, result,
                      T(MSG_INVALID_HTTPS_RESPONSE, "Invalid HTTPS response."));
        goto done;
    }
    body_start = find_header_end(response.data, response.length);
    if (!body_start) {
        result = AMG_ERR_PROTOCOL;
        amg_error_set(error, result,
                      T(MSG_HTTPS_HEADER_IS_INCOMPLETE, "HTTPS header is incomplete."));
        goto done;
    }
    header_length = (size_t)(body_start - response.data);
    if (location && location_capacity)
        (void)header_value(response.data, header_length,
                           "Location", location, location_capacity);
    if (status && (*status == 301 || *status == 302 || *status == 303 ||
                   *status == 307 || *status == 308)) {
        result = AMG_OK;
        goto done;
    }
    if (!status || *status < 200 || *status >= 300) {
        char message[256];
        result = AMG_ERR_PROTOCOL;
        amg_tr_snprintf(message, sizeof(message), MSG_GITHUB_RETURNED_HTTP_STATUS_VALUE, "GitHub returned HTTP status %d.", status ? *status : 0);
        amg_error_set(error, result, message);
        goto done;
    }
    raw_body_length = response.length - header_length;
    transfer_encoding[0] = 0;
    content_length_text[0] = 0;
    (void)header_value(response.data, header_length, "Transfer-Encoding",
                       transfer_encoding, sizeof(transfer_encoding));
    (void)header_value(response.data, header_length, "Content-Length",
                       content_length_text, sizeof(content_length_text));
    if (string_contains_nocase(transfer_encoding, "chunked")) {
        result = decode_chunked_body(body_start, raw_body_length, body);
    } else if (content_length_text[0]) {
        char *endptr = NULL;
        unsigned long expected = strtoul(content_length_text, &endptr, 10);
        if (endptr == content_length_text || *endptr ||
            expected > (unsigned long)raw_body_length) {
            result = AMG_ERR_PROTOCOL;
        } else {
            result = amg_buffer_append(body, body_start, (size_t)expected);
        }
    } else {
        result = amg_buffer_append(body, body_start, raw_body_length);
    }
    if (result == AMG_OK && body->length > max_body) result = AMG_ERR_LIMIT;
    if (result != AMG_OK && error && error->code == AMG_OK)
        amg_error_set(error, result,
                      result == AMG_ERR_LIMIT
                        ? T(MSG_DOWNLOAD_IS_TOO_LARGE, "Download is too large.")
                        : T(MSG_HTTPS_DATA_COULD_NOT_BE_PARSED, "HTTPS data could not be parsed."));

done:
    if (connection) amg_tls_close(connection);
    amg_buffer_free(&request);
    amg_buffer_free(&response);
    if (result == AMG_OK) amg_error_set(error, AMG_OK, "");
    return result;
}

int gru_fetch(const char *url, size_t max_body,
                            AmgBuffer *body, AmgError *error)
{
    char current[AMG_UPDATE_HTTP_URL_MAX];
    unsigned redirect;
    if (!url || strlen(url) >= sizeof(current)) return AMG_ERR_LIMIT;
    strcpy(current, url);
    for (redirect = 0U; redirect <= AMG_UPDATE_REDIRECT_MAX; ++redirect) {
        char location[AMG_UPDATE_HTTP_URL_MAX];
        char next[AMG_UPDATE_HTTP_URL_MAX];
        int status = 0;
        int result;
        amg_buffer_free(body);
        amg_buffer_init(body);
        result = https_get_once(current, max_body, body, &status,
                                location, sizeof(location), error);
        if (result != AMG_OK) return result;
        if (status >= 200 && status < 300) return AMG_OK;
        if (!(status == 301 || status == 302 || status == 303 ||
              status == 307 || status == 308) || !location[0] ||
            !resolve_redirect(current, location, next, sizeof(next))) {
            amg_error_set(error, AMG_ERR_PROTOCOL,
                          T(MSG_GITHUB_REDIRECT_IS_INVALID, "GitHub redirect is invalid."));
            return AMG_ERR_PROTOCOL;
        }
        strcpy(current, next);
    }
    amg_error_set(error, AMG_ERR_PROTOCOL,
                  T(MSG_TOO_MANY_GITHUB_REDIRECTS, "Too many GitHub redirects."));
    return AMG_ERR_PROTOCOL;
}

