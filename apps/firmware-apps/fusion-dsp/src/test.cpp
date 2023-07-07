
#include <bosepro/configuration.h>
#include <bosepro/parameters.h>
#include <bosepro/session.h>

#include <jack/jack.h>
#include <spdlog/spdlog.h>

#include <unistd.h>


jack_client_t *jack_client;


typedef struct {
    jack_client_t *jack_client;
    bosepro::Session *session;
    int total_frames;
} Stuff;


int rt_process(jack_nframes_t nframes, void *arg)
{
    Stuff *stuff = (Stuff *)arg;
    stuff->total_frames += nframes;

    stuff->session->process();
    return 0;
}


int main()
{
    spdlog::set_level(spdlog::level::trace);
    SPDLOG_INFO("bosepro test");
    Stuff stuff;
    jack_status_t jack_status;
    stuff.jack_client = jack_client_open("bosepro", JackNullOption,
                                         &jack_status, NULL);
    jack_client = stuff.jack_client;

    bosepro::Configuration configuration("config/test.json");
    bosepro::Parameters parameters("config/parameters.json");
    bosepro::Session session(configuration.get_session(), parameters);

    stuff.session = &session;

    jack_set_process_callback(stuff.jack_client, rt_process, &stuff);

    jack_activate(stuff.jack_client);

    sleep(-1);
    return 0;
}
