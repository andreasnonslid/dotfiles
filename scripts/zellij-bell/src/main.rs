use std::collections::BTreeMap;
use zellij_tile::prelude::*;

#[derive(Default)]
struct State;

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, _: BTreeMap<String, String>) {
        hide_self();
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        if let Some(payload) = pipe_message.payload.as_deref() {
            if let Some((pos, name)) = payload.split_once('\t') {
                if let Ok(pos) = pos.parse() {
                    rename_tab(pos, name);
                }
            }
        }
        unblock_cli_pipe_input(&pipe_message.name);
        false
    }
}
