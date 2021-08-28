#include <pulse/pulseaudio.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static void sink_callback(pa_context* context, const pa_sink_info* info, int eol, void* userdata) {
	(void)context;
	(void)userdata;

	if (eol > 0)
		return;

	double volume = ((double)pa_cvolume_avg(&info->volume) / PA_VOLUME_NORM) * 100;
	if (info->mute) {
		printf("bV:M% 3.f%%\n", volume);
	} else {
		printf("gV:% 3.f%%\n", volume);
	}
	fflush(stdout);
}

static void server_info_callback(pa_context* context, const pa_server_info* info, void* userdata) {
	(void)userdata;

	// The default_sink_name is temporarily "@DEFAULT_SINK@" when we change profiles
	// This breaks stuff
	if (strcmp(info->default_sink_name, "@DEFAULT_SINK@") != 0) {
		pa_operation* o = pa_context_get_sink_info_by_name(context, info->default_sink_name, sink_callback, NULL);
		pa_operation_unref(o);
	}
}

inline static void update_status(pa_context* context) {
	pa_operation* o = pa_context_get_server_info(context, server_info_callback, NULL);
	pa_operation_unref(o);
}

static void subscribe_callback(pa_context* context, pa_subscription_event_type_t type, uint32_t idx, void* userdata) {
	(void)idx;
	(void)userdata;

	unsigned int event_facility = type & PA_SUBSCRIPTION_EVENT_FACILITY_MASK;
	if (event_facility != PA_SUBSCRIPTION_EVENT_SINK && event_facility != PA_SUBSCRIPTION_EVENT_SERVER) {
		return;
	}

	update_status(context);
}

static void context_callback(pa_context* context, void* userdata) {
	(void)userdata;

	pa_context_state_t state = pa_context_get_state(context);
	if (state != PA_CONTEXT_READY)
		return;

	update_status(context);

	pa_context_set_subscribe_callback(context, subscribe_callback, NULL);
	pa_operation* o =
		pa_context_subscribe(context, PA_SUBSCRIPTION_MASK_SINK | PA_SUBSCRIPTION_MASK_SERVER, NULL, NULL);
	pa_operation_unref(o);
}

static pa_mainloop* try_connecting(void) {
	pa_mainloop* loop = pa_mainloop_new();

	pa_mainloop_api* loop_api = pa_mainloop_get_api(loop);
	pa_context* context = pa_context_new(loop_api, "Volume Monitor");
	if (pa_context_connect(context, NULL, PA_CONTEXT_NOFAIL, NULL) < 0) {
		printf("bWaiting for pulse...\n");
		fflush(stdout);

		pa_context_unref(context);
		pa_mainloop_free(loop);

		sleep(10);
		return NULL;
	}
	pa_context_set_state_callback(context, context_callback, NULL);
	return loop;
}

int main(void) {
	// For some reason i can't get the auto reconnect to work
	// We'll juste wait for pipewire-pulse to start
	sleep(5);

	pa_mainloop* loop = NULL;
	while (loop == NULL)
		loop = try_connecting();

	int ret;
	pa_mainloop_run(loop, &ret);
	return ret;
}
